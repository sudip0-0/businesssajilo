import { createClient } from "npm:@supabase/supabase-js@2";
import { isUnregisteredTokenError } from "./push_policy.ts";

const allowedOrigin = Deno.env.get("ALLOWED_ORIGIN");
if (!allowedOrigin) {
  throw new Error("ALLOWED_ORIGIN must be set");
}
if (allowedOrigin.trim() === "*") {
  // Wildcard CORS defeats the origin allow-list model; refuse to serve it.
  throw new Error(
    "ALLOWED_ORIGIN must be a concrete origin, not '*' — set it via `supabase secrets set ALLOWED_ORIGIN=https://…`",
  );
}

const corsHeaders = {
  "Access-Control-Allow-Origin": allowedOrigin,
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!serviceKey || authHeader !== `Bearer ${serviceKey}`) {
      return json({ error: "Unauthorized" }, 401);
    }

    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      // Malformed JSON is a client error, not a server fault — the outer
      // catch-all maps to 500.
      return json({ error: "Invalid request body" }, 400);
    }
    const notificationId =
      body.notification_id ?? body.record?.id ?? body.id;
    if (!notificationId) {
      return json({ error: "notification_id required" }, 400);
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      serviceKey,
    );

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

    // Atomic claim: only the invocation whose conditional update touches a
    // row proceeds. Concurrent webhook deliveries (check-then-act race)
    // lose here instead of double-sending.
    const { data: claimed, error: claimError } = await supabaseAdmin
      .from("notifications")
      .update({ pushed_at: new Date().toISOString() })
      .eq("id", notificationId)
      .eq("pushed_at", null)
      .select("id");
    if (claimError || !claimed || claimed.length === 0) {
      return json({
        pushed: false,
        reason: "already_pushed",
        notification_id: notificationId,
      });
    }

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

    const accessToken = await getFcmAccessToken(fcmJson);
    const projectId = JSON.parse(fcmJson).project_id as string;
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
        .in("token", invalidTokens);
    }

    // pushed_at was already stamped by the atomic claim above — no need to
    // re-stamp. Report partial failure so the webhook caller can see it.
    return json({
      pushed: sent > 0,
      notification_id: notificationId,
      sent,
      failed,
    });
  } catch (err) {
    console.error("notify failed", err instanceof Error ? err.message : err);
    return json({ error: "Push dispatch failed" }, 500);
  }
});

function titleFor(_type: string, _payload: unknown): string {
  // PII policy: FCM payloads must never contain customer names or amounts.
  // The app renders the detailed title locally from the notification row
  // (lib/features/notifications/notification_labels.dart); the FCM title is
  // only the OS shade fallback, so keep it generic per type.
  return TITLE_BY_TYPE[_type] ?? "BusinessSajilo";
}

// FCM OAuth tokens are valid ~1h; minting an RS256 JWT + token round-trip per
// dispatch costs 200-500ms. Cache in module scope until shortly before expiry.
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
  });

  if (!tokenRes.ok) {
    throw new Error(`FCM auth failed: ${await tokenRes.text()}`);
  }

  const tokenJson = await tokenRes.json();
  const token = tokenJson.access_token as string;
  fcmTokenCache = {
    token,
    // exp is iat+3600 in seconds; keep wall-clock ms with a safety margin
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
