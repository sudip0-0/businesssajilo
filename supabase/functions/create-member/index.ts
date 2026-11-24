import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildCorsHeaders,
  createRateLimiter,
  EMAIL_RE,
  isSyntheticPhoneEmail,
  MAX_FIELD_LEN,
  MAX_MONEY_PAISA,
  NO_SESSION_CLIENT_OPTIONS,
  normalizePhone,
  parseJsonObject,
  phoneLoginEmail,
  str,
  validatePassword,
} from "../_shared/validation.ts";

const corsHeaders = buildCorsHeaders(Deno.env.get("ALLOWED_ORIGIN"));

const allowedRoles = ["sales", "warehouse", "customer"] as const;

const isRateLimited = createRateLimiter({
  windowMs: 60_000,
  maxPerWindow: 30,
  maxTrackedKeys: 10_000,
});

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
    ...NO_SESSION_CLIENT_OPTIONS,
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userError,
  } = await supabaseUser.auth.getUser();
  if (userError || !user) {
    return json({ error: "Unauthorized" }, 401);
  }

  if (isRateLimited(user.id)) {
    return json({ error: "Too many attempts. Try again later." }, 429);
  }

  const supabaseAdmin = createClient(
    supabaseUrl,
    serviceKey,
    NO_SESSION_CLIENT_OPTIONS,
  );

  const { data: caller, error: callerError } = await supabaseAdmin
    .from("members")
    .select("id, business_id, role, is_active")
    .eq("auth_user_id", user.id)
    .eq("is_active", true)
    .single();

  if (callerError || !caller || caller.role !== "owner") {
    return json({ error: "Only the business owner can create members" }, 403);
  }

  const body = await parseJsonObject(req);
  if (!body) {
    return json({ error: "Invalid request body" }, 400);
  }

  const suppliedEmail = str(body.email)?.trim().toLowerCase() || null;
  const password = str(body.password);
  const role = str(body.role);
  const displayName = str(body.displayName)?.trim();
  const rawPhone = str(body.phone)?.trim() || null;
  const shopName = str(body.shopName)?.trim() || null;
  const contactName = str(body.contactName)?.trim() || null;
  const address = str(body.address)?.trim() || null;
  const openingBalance = body.openingBalance;

  // Normalize phone if provided; it doubles as a login identifier.
  let phone: string | null = null;
  if (rawPhone) {
    phone = normalizePhone(rawPhone);
    if (!phone) {
      return json({ error: "Invalid phone number" }, 400);
    }
  }

  if (!password || !role || !displayName) {
    return json({ error: "Missing required fields" }, 400);
  }

  // Reject manually supplied synthetic phone-login emails; they may only be
  // derived from a validated Nepali phone number.
  let email = suppliedEmail;
  if (email && isSyntheticPhoneEmail(email)) {
    return json({ error: "Invalid email address" }, 400);
  }
  if (!email) {
    if (!phone) {
      return json({ error: "Email or phone number is required" }, 400);
    }
    email = phoneLoginEmail(phone);
  }
  if (!EMAIL_RE.test(email) || email.length > MAX_FIELD_LEN) {
    return json({ error: "Invalid email address" }, 400);
  }

  // Phone doubles as a global login identifier. Do NOT pre-check across all
  // businesses — that lets any caller enumerate which phones exist anywhere
  // on the platform. The partial unique index (active rows only) is the
  // backstop; a violation surfaces below as the same generic 409.
  const passwordError = validatePassword(password);
  if (passwordError) {
    return json({ error: passwordError }, 400);
  }
  if (!allowedRoles.includes(role as typeof allowedRoles[number])) {
    return json({ error: "Invalid role" }, 400);
  }
  if (role === "customer" && !shopName) {
    return json({ error: "shopName is required for customer role" }, 400);
  }
  if (
    openingBalance !== undefined &&
    openingBalance !== null &&
    (typeof openingBalance !== "number" ||
      !Number.isSafeInteger(openingBalance) ||
      Math.abs(openingBalance) > MAX_MONEY_PAISA)
  ) {
    return json({ error: "openingBalance must be an integer (paisa)" }, 400);
  }
  for (const v of [displayName, phone, shopName, contactName, address]) {
    if (v && v.length > MAX_FIELD_LEN) {
      return json({ error: "Field too long" }, 400);
    }
  }

  let userId: string | null = null;
  try {
    const { data: authData, error: authError } = await supabaseAdmin.auth
      .admin.createUser({
        email,
        password,
        email_confirm: true,
      });
    if (authError) {
      console.error("create-member createUser failed", authError.status ?? "unknown");
      return json({ error: "Could not create account with this email" }, 400);
    }
    userId = authData.user.id;

    // Customers default to portal-off (inactive) so random passwords cannot
    // be used to sign in until the owner explicitly enables portal access;
    // staff roles default active. Explicit boolean overrides either way.
    const isActive = typeof body.isActive === "boolean"
      ? body.isActive
      : role !== "customer";

    const { data: member, error: memberError } = await supabaseAdmin
      .from("members")
      .insert({
        business_id: caller.business_id,
        auth_user_id: userId,
        role,
        display_name: displayName,
        phone,
        is_active: isActive,
      })
      .select("id")
      .single();
    if (memberError) {
      // Postgres unique_violation on the partial phone index — same generic
      // message regardless of which business owns the conflicting member.
      if (memberError.code === "23505") {
        await supabaseAdmin.auth.admin.deleteUser(userId);
        return json({ error: "Phone number already registered" }, 409);
      }
      throw memberError;
    }

    let customerId: string | null = null;
    if (role === "customer") {
      const { data: customer, error: customerError } = await supabaseAdmin
        .from("customers")
        .insert({
          business_id: caller.business_id,
          member_id: member.id,
          shop_name: shopName,
          contact_name: contactName ?? displayName,
          phone,
          address,
          opening_balance: typeof openingBalance === "number"
            ? openingBalance
            : 0,
        })
        .select("id")
        .single();
      if (customerError) {
        // Roll back the member so we don't leave a half-created customer login.
        await supabaseAdmin.from("members").delete().eq("id", member.id);
        throw customerError;
      }
      customerId = customer.id;
    }

    return json({ memberId: member.id, customerId });
  } catch (error) {
    console.error(
      "create-member failed",
      error instanceof Error ? error.name : "unknown",
    );
    if (userId) {
      await supabaseAdmin.auth.admin.deleteUser(userId);
    }
    return json({ error: "Could not create member. Please try again." }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
