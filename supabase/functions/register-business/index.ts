import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("register-business request", { method: req.method });
    const body = await req.json();
    const {
      email,
      password,
      displayName,
      businessName,
      businessNameNp,
      phone,
      address,
    } = body;

    if (!email || !password || !displayName || !businessName) {
      return json({ error: "Missing required fields" }, 400);
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: authData, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        app_metadata: {},
      });
    if (authError) throw authError;

    const { data: business, error: bizError } = await supabaseAdmin
      .from("businesses")
      .insert({
        name: businessName,
        name_np: businessNameNp ?? null,
        phone: phone ?? null,
        address: address ?? null,
      })
      .select("id")
      .single();
    if (bizError) throw bizError;

    const { data: member, error: memberError } = await supabaseAdmin
      .from("members")
      .insert({
        business_id: business.id,
        auth_user_id: authData.user.id,
        role: "owner",
        display_name: displayName,
        phone: phone ?? null,
      })
      .select("id")
      .single();
    if (memberError) throw memberError;

    return json({ businessId: business.id, memberId: member.id });
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
