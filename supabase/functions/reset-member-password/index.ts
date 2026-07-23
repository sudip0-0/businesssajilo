import { createClient } from "npm:@supabase/supabase-js@2";
import {
  isUuid,
  str,
  validatePassword,
} from "../_shared/validation.ts";

const allowedOrigin = Deno.env.get("ALLOWED_ORIGIN");
if (!allowedOrigin) {
  throw new Error("ALLOWED_ORIGIN must be set");
}

const corsHeaders = {
  "Access-Control-Allow-Origin": allowedOrigin,
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  const supabaseUser = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userError,
  } = await supabaseUser.auth.getUser();
  if (userError || !user) {
    return json({ error: "Unauthorized" }, 401);
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceKey);

  const { data: caller, error: callerError } = await supabaseAdmin
    .from("members")
    .select("id, business_id, role, is_active")
    .eq("auth_user_id", user.id)
    .eq("is_active", true)
    .single();

  if (callerError || !caller || caller.role !== "owner") {
    return json(
      { error: "Only the business owner can reset member passwords" },
      403,
    );
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request body" }, 400);
  }

  const memberId = str(body.memberId);
  const newPassword = str(body.newPassword);

  if (!memberId || !newPassword) {
    return json({ error: "Missing required fields" }, 400);
  }
  if (!isUuid(memberId)) {
    return json({ error: "Invalid memberId" }, 400);
  }
  const passwordError = validatePassword(newPassword);
  if (passwordError) {
    return json({ error: passwordError }, 400);
  }

  // Target must be an active member of the caller's own business, and the
  // owner cannot reset their own password this way (use email reset).
  const { data: target, error: targetError } = await supabaseAdmin
    .from("members")
    .select("id, business_id, auth_user_id, is_active")
    .eq("id", memberId)
    .eq("business_id", caller.business_id)
    .eq("is_active", true)
    .single();

  if (targetError || !target) {
    return json({ error: "Member not found" }, 404);
  }
  if (target.auth_user_id === user.id) {
    return json({ error: "Use email password reset for your own account" }, 400);
  }

  try {
    const { error: updateError } = await supabaseAdmin.auth.admin
      .updateUserById(target.auth_user_id, { password: newPassword });
    if (updateError) throw updateError;

    // Force the member to pick their own password on next login.
    const { error: flagError } = await supabaseAdmin
      .from("members")
      .update({ must_change_password: true })
      .eq("id", target.id);
    if (flagError) throw flagError;

    // Revoke existing sessions so old devices are signed out immediately.
    const { error: revokeError } = await supabaseAdmin.rpc(
      "revoke_member_sessions",
      { p_auth_user_id: target.auth_user_id },
    );
    if (revokeError) {
      // Non-fatal: password already changed; sessions expire on refresh.
      console.error(
        "reset-member-password revoke failed",
        revokeError.message,
      );
    }

    return json({ ok: true });
  } catch (error) {
    console.error(
      "reset-member-password failed",
      error instanceof Error ? error.message : error,
    );
    return json({ error: "Could not reset password. Please try again." }, 400);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
