import { createClient } from "npm:@supabase/supabase-js@2";

const allowedOrigin = Deno.env.get("ALLOWED_ORIGIN") ?? "*";

const corsHeaders = {
  "Access-Control-Allow-Origin": allowedOrigin,
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_FIELD_LEN = 200;

// Naive in-memory rate limit per isolate (defense in depth; resets on cold start).
const attempts = new Map<string, { count: number; windowStart: number }>();
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 5;

function rateLimited(key: string): boolean {
  const now = Date.now();
  const entry = attempts.get(key);
  if (!entry || now - entry.windowStart > WINDOW_MS) {
    attempts.set(key, { count: 1, windowStart: now });
    return false;
  }
  entry.count += 1;
  return entry.count > MAX_PER_WINDOW;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
    "unknown";
  if (rateLimited(ip)) {
    return json({ error: "Too many attempts. Try again later." }, 429);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request body" }, 400);
  }

  const email = str(body.email)?.trim().toLowerCase();
  const password = str(body.password);
  const displayName = str(body.displayName)?.trim();
  const businessName = str(body.businessName)?.trim();
  const businessNameNp = str(body.businessNameNp)?.trim() || null;
  const phone = str(body.phone)?.trim() || null;
  const address = str(body.address)?.trim() || null;

  if (!email || !password || !displayName || !businessName) {
    return json({ error: "Missing required fields" }, 400);
  }
  if (!EMAIL_RE.test(email) || email.length > MAX_FIELD_LEN) {
    return json({ error: "Invalid email address" }, 400);
  }
  if (password.length < 8 || password.length > 72) {
    return json({ error: "Password must be 8-72 characters" }, 400);
  }
  for (const v of [displayName, businessName, businessNameNp, phone, address]) {
    if (v && v.length > MAX_FIELD_LEN) {
      return json({ error: "Field too long" }, 400);
    }
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
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
      console.error("register-business createUser failed", authError.message);
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
    if (memberError) throw memberError;

    return json({ businessId: business.id, memberId: member.id });
  } catch (error) {
    // Best-effort cleanup so a failed registration leaves no orphans.
    console.error(
      "register-business failed",
      error instanceof Error ? error.message : error,
    );
    if (businessId) {
      await supabaseAdmin.from("businesses").delete().eq("id", businessId);
    }
    if (userId) {
      await supabaseAdmin.auth.admin.deleteUser(userId);
    }
    return json({ error: "Registration failed. Please try again." }, 400);
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
