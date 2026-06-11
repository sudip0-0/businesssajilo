import { createClient } from "npm:@supabase/supabase-js@2";

const allowedOrigin = Deno.env.get("ALLOWED_ORIGIN") ?? "*";

const corsHeaders = {
  "Access-Control-Allow-Origin": allowedOrigin,
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const allowedRoles = ["sales", "warehouse", "customer"] as const;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_FIELD_LEN = 200;

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

  const email = str(body.email)?.trim().toLowerCase();
  const password = str(body.password);
  const role = str(body.role);
  const displayName = str(body.displayName)?.trim();
  const phone = str(body.phone)?.trim() || null;
  const shopName = str(body.shopName)?.trim() || null;
  const contactName = str(body.contactName)?.trim() || null;
  const address = str(body.address)?.trim() || null;
  const openingBalance = body.openingBalance;

  if (!email || !password || !role || !displayName) {
    return json({ error: "Missing required fields" }, 400);
  }
  if (!EMAIL_RE.test(email) || email.length > MAX_FIELD_LEN) {
    return json({ error: "Invalid email address" }, 400);
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

    const { data: member, error: memberError } = await supabaseAdmin
      .from("members")
      .insert({
        business_id: caller.business_id,
        auth_user_id: userId,
        role,
        display_name: displayName,
        phone,
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
