import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const allowedRoles = ["sales", "warehouse", "customer"] as const;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
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

    const body = await req.json();
    const {
      email,
      password,
      role,
      displayName,
      phone,
      shopName,
      contactName,
      address,
    } = body;

    if (!email || !password || !role || !displayName) {
      return json({ error: "Missing required fields" }, 400);
    }

    if (!allowedRoles.includes(role)) {
      return json({ error: "Invalid role" }, 400);
    }

    if (role === "customer" && !shopName) {
      return json({ error: "shopName is required for customer role" }, 400);
    }

    const { data: authData, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });
    if (authError) throw authError;

    const { data: member, error: memberError } = await supabaseAdmin
      .from("members")
      .insert({
        business_id: caller.business_id,
        auth_user_id: authData.user.id,
        role,
        display_name: displayName,
        phone: phone ?? null,
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
          phone: phone ?? null,
          address: address ?? null,
        })
        .select("id")
        .single();
      if (customerError) throw customerError;
      customerId = customer.id;
    }

    return json({ memberId: member.id, customerId });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return json({ error: message }, 400);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
