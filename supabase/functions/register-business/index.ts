import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildCorsHeaders,
  createRateLimiter,
  EMAIL_RE,
  getClientIp,
  isSyntheticPhoneEmail,
  MAX_FIELD_LEN,
  NO_SESSION_CLIENT_OPTIONS,
  normalizePhone,
  parseJsonObject,
  str,
  validatePassword,
} from "../_shared/validation.ts";

const corsHeaders = buildCorsHeaders(Deno.env.get("ALLOWED_ORIGIN"));

// In-memory rate limit per isolate (defense in depth; resets on cold start).
const isRateLimited = createRateLimiter({
  windowMs: 60_000,
  maxPerWindow: 5,
  maxTrackedKeys: 10_000,
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const ip = getClientIp(req);
  if (isRateLimited(ip)) {
    return json({ error: "Too many attempts. Try again later." }, 429);
  }

  const body = await parseJsonObject(req);
  if (!body) {
    return json({ error: "Invalid request body" }, 400);
  }

  const email = str(body.email)?.trim().toLowerCase();
  const password = str(body.password);
  const displayName = str(body.displayName)?.trim();
  const businessName = str(body.businessName)?.trim();
  const businessNameNp = str(body.businessNameNp)?.trim() || null;
  const rawPhone = str(body.phone)?.trim() || null;
  const address = str(body.address)?.trim() || null;

  if (!email || !password || !displayName || !businessName) {
    return json({ error: "Missing required fields" }, 400);
  }
  if (
    !EMAIL_RE.test(email) ||
    email.length > MAX_FIELD_LEN ||
    isSyntheticPhoneEmail(email)
  ) {
    return json({ error: "Invalid email address" }, 400);
  }
  const passwordError = validatePassword(password);
  if (passwordError) {
    return json({ error: passwordError }, 400);
  }

  let phone: string | null = null;
  if (rawPhone) {
    phone = normalizePhone(rawPhone);
    if (!phone) {
      return json({ error: "Invalid phone number" }, 400);
    }
  }

  for (const v of [displayName, businessName, businessNameNp, phone, address]) {
    if (v && v.length > MAX_FIELD_LEN) {
      return json({ error: "Field too long" }, 400);
    }
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    NO_SESSION_CLIENT_OPTIONS,
  );

  let userId: string | null = null;
  let businessId: string | null = null;
  try {
    const { data: authData, error: authError } = await supabaseAdmin.auth
      .admin.createUser({
        email,
        password,
        email_confirm: true,
        app_metadata: {},
      });
    if (authError) {
      // Duplicate email or weak password — keep the message generic.
      console.error("register-business createUser failed", authError.status ?? "unknown");
      return json({ error: "Could not create account with this email" }, 400);
    }
    userId = authData.user.id;

    const { data: business, error: bizError } = await supabaseAdmin
      .from("businesses")
      .insert({
        name: businessName,
        name_np: businessNameNp,
        phone,
        address,
      })
      .select("id")
      .single();
    if (bizError) throw bizError;
    businessId = business.id;

    const { data: member, error: memberError } = await supabaseAdmin
      .from("members")
      .insert({
        business_id: business.id,
        auth_user_id: userId,
        role: "owner",
        display_name: displayName,
        phone,
      })
      .select("id")
      .single();
    if (memberError) {
      if (memberError.code === "23505") {
        await supabaseAdmin.from("businesses").delete().eq("id", businessId);
        await supabaseAdmin.auth.admin.deleteUser(userId);
        return json({ error: "Phone number already registered" }, 409);
      }
      throw memberError;
    }

    return json({ businessId: business.id, memberId: member.id });
  } catch (error) {
    // Best-effort cleanup so a failed registration leaves no orphans.
    console.error(
      "register-business failed",
      error instanceof Error ? error.name : "unknown",
    );
    if (businessId) {
      await supabaseAdmin.from("businesses").delete().eq("id", businessId);
    }
    if (userId) {
      await supabaseAdmin.auth.admin.deleteUser(userId);
    }
    return json({ error: "Registration failed. Please try again." }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
