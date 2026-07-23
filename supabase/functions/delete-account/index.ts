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

// Modes:
//  - "self": non-owner member deletes their own account. Personal identity is
//    anonymized; the business's financial records (bills, ledger) are kept
//    because they belong to the business (names are snapshotted).
//  - "business": owner permanently deletes the whole business and all data.
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

  if (callerError || !caller) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request body" }, 400);
  }

  const mode = str(body.mode);

  try {
    if (mode === "self") {
      if (caller.role === "owner") {
        return json(
          { error: "Owners must delete the business instead" },
          400,
        );
      }

      // Require password confirmation so a stolen session alone cannot
      // delete a member account.
      const password = str(body.password);
      if (!password) {
        return json({ error: "Password required to delete account" }, 400);
      }
      if (!user.email) {
        return json({ error: "Account has no email for re-authentication" }, 400);
      }
      const { error: reauthError } = await supabaseUser.auth.signInWithPassword({
        email: user.email,
        password,
      });
      if (reauthError) {
        return json({ error: "Invalid password" }, 403);
      }

      const { data: authUserId, error } = await supabaseAdmin.rpc(
        "anonymize_member_for_deletion",
        { p_member_id: caller.id },
      );
      if (error) throw error;

      const { error: deleteError } = await supabaseAdmin.auth.admin
        .deleteUser(authUserId as string);
      if (deleteError) throw deleteError;

      return json({ ok: true });
    }

    if (mode === "business") {
      if (caller.role !== "owner") {
        return json(
          { error: "Only the business owner can delete the business" },
          403,
        );
      }

      // Require recent password confirmation so a stolen session alone
      // cannot purge the entire business.
      const password = str(body.password);
      if (!password) {
        return json({ error: "Password required to delete business" }, 400);
      }
      if (!user.email) {
        return json({ error: "Account has no email for re-authentication" }, 400);
      }
      const { error: reauthError } = await supabaseUser.auth.signInWithPassword({
        email: user.email,
        password,
      });
      if (reauthError) {
        return json({ error: "Invalid password" }, 403);
      }

      const businessId = caller.business_id as string;

      // Remove tenant storage objects (product + chat images).
      for (const bucket of ["product-images", "order-chat-images"]) {
        try {
          await removeFolder(supabaseAdmin, bucket, businessId);
        } catch (e) {
          // Non-fatal: DB purge is the source of truth; orphaned files can
          // be cleaned up manually.
          console.error(`delete-account storage cleanup failed (${bucket})`, e);
        }
      }

      const { data: authUserIds, error } = await supabaseAdmin.rpc(
        "purge_business",
        { p_business_id: businessId },
      );
      if (error) throw error;

      for (const id of (authUserIds as string[]) ?? []) {
        const { error: deleteError } = await supabaseAdmin.auth.admin
          .deleteUser(id);
        if (deleteError) {
          console.error(
            "delete-account auth user cleanup failed",
            id,
            deleteError.message,
          );
        }
      }

      return json({ ok: true });
    }

    return json({ error: "Invalid mode" }, 400);
  } catch (error) {
    console.error(
      "delete-account failed",
      error instanceof Error ? error.message : error,
    );
    return json({ error: "Could not delete account. Please try again." }, 400);
  }
});

async function removeFolder(
  // deno-lint-ignore no-explicit-any
  admin: any,
  bucket: string,
  folder: string,
) {
  const { data: files } = await admin.storage.from(bucket).list(folder, {
    limit: 1000,
  });
  if (!files || files.length === 0) return;
  const paths = files.map((f: { name: string }) => `${folder}/${f.name}`);
  await admin.storage.from(bucket).remove(paths);
}

function str(v: unknown): string | null {
  return typeof v === "string" ? v : null;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
