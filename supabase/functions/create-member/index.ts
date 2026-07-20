import { createClient } from "npm:@supabase/supabase-js@2";

const allowedOrigin = Deno.env.get("ALLOWED_ORIGIN");
if (!allowedOrigin) {
  throw new Error("ALLOWED_ORIGIN must be set");
}

const corsHeaders = {
  "Access-Control-Allow-Origin": allowedOrigin,
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const allowedRoles = ["sales", "warehouse", "customer"] as const;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_FIELD_LEN = 200;

// Members without a real email log in by phone: the auth account is created
// with a synthetic email derived from the normalized phone number. Must stay
// in sync with lib/core/utils/login_identifier.dart.
const PHONE_LOGIN_DOMAIN = "phone.businesssajilo.app";

/** Normalizes a Nepali phone number to +977XXXXXXXXXX, or null if invalid. */
function normalizePhone(raw: string): string | null {
  const digits = raw.replace(/[\s\-()]/g, "").replace(/^\+/, "");
  let local: string;
  if (digits.startsWith("977")) {
    local = digits.slice(3);
  } else if (/^0\d{9,}$/.test(digits)) {
    local = digits.slice(1);
  } else {
    local = digits;
  }
  if (!/^9\d{9}$/.test(local)) return null;
  return `+977${local}`;
}

/** Synthetic auth email for phone-based logins: 98XXXXXXXX@phone.… */
function phoneLoginEmail(normalizedPhone: string): string {
  return `${normalizedPhone.slice(4)}@${PHONE_LOGIN_DOMAIN}`;
}

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
    return json({ error: "Only the business owner can create members" }, 403);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request body" }, 400);
  }

  let email = str(body.email)?.trim().toLowerCase() || null;
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
  // Email is optional when a phone is given: derive a synthetic login email.
  if (!email) {
    if (!phone) {
      return json({ error: "Email or phone number is required" }, 400);
    }
    email = phoneLoginEmail(phone);
  }
  if (!EMAIL_RE.test(email) || email.length > MAX_FIELD_LEN) {
    return json({ error: "Invalid email address" }, 400);
  }
  // Phone doubles as a global login identifier — enforce uniqueness early
  // for a clear error (DB unique index is the backstop).
  if (phone) {
    const { data: phoneClash } = await supabaseAdmin
      .from("members")
      .select("id")
      .eq("phone", phone)
      .eq("is_active", true)
      .maybeSingle();
    if (phoneClash) {
      return json({ error: "Phone number already registered" }, 409);
    }
  }
  if (password.length < 8 || password.length > 72) {
    return json({ error: "Password must be 8-72 characters" }, 400);
  }
  if (!allowedRoles.includes(role as typeof allowedRoles[number])) {
    return json({ error: "Invalid role" }, 400);
  }
  if (role === "customer" && !shopName) {
    return json({ error: "shopName is required for customer role" }, 400);
  }
  if (
    openingBalance !== undefined && openingBalance !== null &&
    (typeof openingBalance !== "number" ||
      !Number.isSafeInteger(openingBalance))
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
      console.error("create-member createUser failed", authError.message);
      return json({ error: "Could not create account with this email" }, 400);
    }
    userId = authData.user.id;

    // Portal-off customers are created inactive so random passwords cannot
    // be used to sign in until the owner enables portal access.
    const isActive = body.isActive === false ? false : true;

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
    if (memberError) throw memberError;

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
      error instanceof Error ? error.message : error,
    );
    if (userId) {
      await supabaseAdmin.auth.admin.deleteUser(userId);
    }
    return json({ error: "Could not create member. Please try again." }, 400);
  }
});

function str(v: unknown): string | null {
  return typeof v === "string" ? v : null;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
