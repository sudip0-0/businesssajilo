import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const TITLE_BY_TYPE: Record<string, string> = {
  order_placed: "New order placed",
  quote_received: "New quote received",
  quote_accepted: "Quote accepted",
  quote_rejected: "Quote rejected",
  order_status: "Order status updated",
  chat_message: "New chat message",
  payment_recorded: "Payment recorded",
  low_stock: "Low stock alert",
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

    const body = await req.json();
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
      .select("id, type, payload, recipient_member_id")
      .eq("id", notificationId)
      .single();
    if (notifError || !notification) {
      return json({ error: "Notification not found" }, 404);
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
    const title = TITLE_BY_TYPE[notification.type] ?? "BusinessSajilo";
    const bodyText = notification.type.replaceAll("_", " ");

    const results = await Promise.all(
      deviceTokens.map((token) =>
        sendFcmMessage(accessToken, projectId, token, title, bodyText, {
          type: notification.type,
          notification_id: notification.id,
          ...notification.payload,
        })
      ),
    );

    return json({
      pushed: true,
      notification_id: notificationId,
      sent: results.filter((r) => r.ok).length,
      failed: results.filter((r) => !r.ok).length,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return json({ error: message }, 500);
  }
});

async function getFcmAccessToken(serviceAccountJson: string): Promise<string> {
  const sa = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
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
  return tokenJson.access_token as string;
}

async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  deviceToken: string,
  title: string,
  body: string,
  data: Record<string, unknown>,
): Promise<{ ok: boolean }> {
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
  return { ok: res.ok };
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
