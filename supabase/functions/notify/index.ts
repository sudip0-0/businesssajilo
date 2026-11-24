import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildCorsHeaders,
  isUuid,
  NO_SESSION_CLIENT_OPTIONS,
  parseJsonObject,
  str,
  timingSafeEqual,
} from "../_shared/validation.ts";
import {
  isUnregisteredTokenError,
  shouldStampPushedAt,
} from "./push_policy.ts";

const corsHeaders = buildCorsHeaders(Deno.env.get("ALLOWED_ORIGIN"));

const TITLE_BY_TYPE: Record<string, string> = {
  order_placed: "New order placed",
  order_received: "Your order was seen",
  quote_received: "New quote received",
  quote_accepted: "Quote accepted",
  quote_rejected: "Quote rejected",
  order_status: "Order status updated",
  payment_recorded: "Payment recorded",
  low_stock: "Low stock alert",
  negative_stock: "Negative stock alert",
  quote_stale: "Quote expired",
  dues_reminder: "Outstanding dues reminder",
};

const FETCH_TIMEOUT_MS = 10_000;
const PROJECT_ID_RE = /^[a-z0-9-]+$/i;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  let claimedNotificationId: string | null = null;
  let claimedAtIso: string | null = null;
  // deno-lint-ignore no-explicit-any
  let adminForRelease: any = null;

  try {
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const authHeader = req.headers.get("Authorization") ?? "";
    if (
      !serviceKey ||
      !timingSafeEqual(authHeader, `Bearer ${serviceKey}`)
    ) {
      return json({ error: "Unauthorized" }, 401);
    }

    const body = await parseJsonObject(req);
    if (!body) {
      return json({ error: "Invalid request body" }, 400);
    }

    const recordObj =
      typeof body.record === "object" && body.record !== null
        ? (body.record as Record<string, unknown>)
        : null;
    const notificationId =
      str(body.notification_id) ?? str(recordObj?.id) ?? str(body.id);
    if (!notificationId || !isUuid(notificationId)) {
      return json({ error: "Valid notification_id required" }, 400);
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      serviceKey,
      NO_SESSION_CLIENT_OPTIONS,
    );
    adminForRelease = supabaseAdmin;

    const { data: notification, error: notifError } = await supabaseAdmin
      .from("notifications")
      .select("id, type, payload, recipient_member_id, pushed_at")
      .eq("id", notificationId)
      .single();
    if (notifError || !notification) {
      return json({ error: "Notification not found" }, 404);
    }

    // Idempotency: webhook replays must not re-send pushes.
    if (notification.pushed_at) {
      return json({
        pushed: false,
        reason: "already_pushed",
        notification_id: notificationId,
      });
    }

    // Check FCM configuration & tokens BEFORE claiming pushed_at so an
    // unconfigured environment or offline tokenless user does not get
    // permanently stamped as pushed.
    const fcmJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!fcmJson) {
      return json({
        pushed: false,
        reason: "fcm_not_configured",
        notification_id: notificationId,
      });
    }

    const { data: tokens, error: tokenError } = await supabaseAdmin
      .from("device_tokens")
      .select("token")
      .eq("member_id", notification.recipient_member_id);
    if (tokenError) throw tokenError;

    const deviceTokens = (tokens ?? []).map((t) => t.token).filter(Boolean);
    if (deviceTokens.length === 0) {
      return json({
        pushed: false,
        reason: "no_device_tokens",
        notification_id: notificationId,
      });
    }

    // Atomic claim: use .is("pushed_at", null) (SQL IS NULL, NOT eq.null).
    // Concurrent webhook deliveries lose here instead of double-sending.
    claimedAtIso = new Date().toISOString();
    const { data: claimed, error: claimError } = await supabaseAdmin
      .from("notifications")
      .update({ pushed_at: claimedAtIso })
      .eq("id", notificationId)
      .is("pushed_at", null)
      .select("id");
    if (claimError || !claimed || claimed.length === 0) {
      claimedAtIso = null;
      return json({
        pushed: false,
        reason: "already_pushed",
        notification_id: notificationId,
      });
    }
    claimedNotificationId = notificationId;

    const parsedSa = JSON.parse(fcmJson) as { project_id?: unknown };
    const projectId = str(parsedSa.project_id)?.trim() ?? "";
    if (!PROJECT_ID_RE.test(projectId)) {
      throw new Error("Invalid FCM project_id");
    }

    const accessToken = await getFcmAccessToken(fcmJson);
    const title = titleFor(notification.type, notification.payload);
    const bodyText = notification.type.replaceAll("_", " ");

    // Only routing identifiers go to FCM — never names/amounts (PII).
    const routingData: Record<string, unknown> = {
      type: notification.type,
      notification_id: notification.id,
    };
    for (const key of [
      "order_id",
      "bill_id",
      "customer_id",
      "product_id",
      "quote_id",
    ]) {
      const value = (notification.payload as Record<string, unknown>)?.[key];
      if (value != null) routingData[key] = value;
    }

    const results = await Promise.all(
      deviceTokens.map((token) =>
        sendFcmMessage(accessToken, projectId, token, title, bodyText, routingData)
      ),
    );

    const sent = results.filter((r) => r.ok).length;
    const failed = results.filter((r) => !r.ok).length;
    const invalidTokens = results
      .filter((r) => !r.ok && r.unregistered)
      .map((r) => r.token);

    if (invalidTokens.length > 0) {
      await supabaseAdmin
        .from("device_tokens")
        .delete()
        .eq("member_id", notification.recipient_member_id)
        .in("token", invalidTokens);
    }

    // Keep pushed_at stamped only when every send succeeded (push_policy.ts);
    // release the claim on partial/total transient failure so retries can recover.
    if (!shouldStampPushedAt(sent, failed)) {
      await releaseClaim(supabaseAdmin, claimedNotificationId, claimedAtIso);
    }
    claimedNotificationId = null;

    return json({
      pushed: sent > 0,
      notification_id: notificationId,
      sent,
      failed,
    });
  } catch (err) {
    if (adminForRelease && claimedNotificationId && claimedAtIso) {
      await releaseClaim(adminForRelease, claimedNotificationId, claimedAtIso);
    }
    console.error("notify failed", err instanceof Error ? err.name : "unknown");
    return json({ error: "Push dispatch failed" }, 500);
  }
});

async function releaseClaim(
  // deno-lint-ignore no-explicit-any
  admin: any,
  notificationId: string,
  claimedAtIso: string,
) {
  try {
    await admin
      .from("notifications")
      .update({ pushed_at: null })
      .eq("id", notificationId)
      .eq("pushed_at", claimedAtIso);
  } catch {
    // Best-effort release; do not mask original failure.
  }
}

function titleFor(_type: string, _payload: unknown): string {
  // PII policy: FCM payloads must never contain customer names or amounts.
  return TITLE_BY_TYPE[_type] ?? "BusinessSajilo";
}

// FCM OAuth tokens are valid ~1h; cache in module scope until shortly before expiry.
let fcmTokenCache: { token: string; expiresAtMs: number } | null = null;

async function getFcmAccessToken(serviceAccountJson: string): Promise<string> {
  const now = Date.now();
  if (fcmTokenCache && now < fcmTokenCache.expiresAtMs - 5 * 60_000) {
    return fcmTokenCache.token;
  }
  const sa = JSON.parse(serviceAccountJson);
  const iat = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat,
    exp: iat + 3600,
  };

  const encoder = new TextEncoder();
  const toBase64Url = (input: string) =>
    btoa(input).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const unsigned = `${toBase64Url(JSON.stringify(header))}.${toBase64Url(JSON.stringify(claim))}`;

  const pem = (sa.private_key as string).replace(/\\n/g, "\n");
  const keyData = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binary = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(unsigned),
  );
  const signedJwt =
    `${unsigned}.${toBase64Url(String.fromCharCode(...new Uint8Array(signature)))}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedJwt,
    }),
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  });

  if (!tokenRes.ok) {
    throw new Error(`FCM auth failed (${tokenRes.status})`);
  }

  const tokenJson = await tokenRes.json();
  const token = tokenJson.access_token as string;
  fcmTokenCache = {
    token,
    expiresAtMs: Date.now() + 55 * 60_000,
  };
  return token;
}

async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  deviceToken: string,
  title: string,
  body: string,
  data: Record<string, unknown>,
): Promise<{ ok: boolean; token: string; unregistered: boolean }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: { title, body },
          data: Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v ?? "")]),
          ),
        },
      }),
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
    },
  );
  const bodyText = res.ok ? "" : await res.text();
  return {
    ok: res.ok,
    token: deviceToken,
    unregistered: !res.ok && isUnregisteredTokenError(res.status, bodyText),
  };
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
