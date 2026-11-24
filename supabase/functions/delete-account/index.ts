import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildCorsHeaders,
  createRateLimiter,
  MAX_PASSWORD_LEN,
  NO_SESSION_CLIENT_OPTIONS,
  parseJsonObject,
  str,
} from "../_shared/validation.ts";

const corsHeaders = buildCorsHeaders(Deno.env.get("ALLOWED_ORIGIN"));

const isRateLimited = createRateLimiter({
  windowMs: 60_000,
  maxPerWindow: 5,
  maxTrackedKeys: 10_000,
});

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

  if (callerError || !caller) {
    return json({ error: "Unauthorized" }, 401);
  }

  const body = await parseJsonObject(req);
  if (!body) {
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
      if (!password || password.length > MAX_PASSWORD_LEN) {
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
      // Already-anonymized member (e.g. replayed request): the auth user is
      // gone or unlinked — treat as success instead of deleteUser(undefined).
      if (!authUserId) {
        return json({ ok: true, already_deleted: true });
      }

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
      if (!password || password.length > MAX_PASSWORD_LEN) {
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

      // Purge DB atomically FIRST so a DB failure does not destroy storage
      // objects prematurely.
      const { data: authUserIds, error } = await supabaseAdmin.rpc(
        "purge_business",
        { p_business_id: businessId },
      );
      if (error) throw error;

      // Remove tenant storage objects (best-effort after DB purge succeeds).
      for (const bucket of ["product-images"]) {
        try {
          await removeFolder(supabaseAdmin, bucket, businessId);
        } catch (e) {
          console.error(
            `delete-account storage cleanup failed (${bucket})`,
            e instanceof Error ? e.name : "unknown",
          );
        }
      }

      for (const id of (authUserIds as string[]) ?? []) {
        const { error: deleteError } = await supabaseAdmin.auth.admin
          .deleteUser(id);
        if (deleteError) {
          console.error("delete-account auth user cleanup failed");
        }
      }

      return json({ ok: true });
    }

    return json({ error: "Invalid mode" }, 400);
  } catch (error) {
    console.error(
      "delete-account failed",
      error instanceof Error ? error.name : "unknown",
    );
    return json({ error: "Could not delete account. Please try again." }, 500);
  }
});

async function removeFolder(
  // deno-lint-ignore no-explicit-any
  admin: any,
  bucket: string,
  folder: string,
  maxDepth = 5,
) {
  if (maxDepth <= 0) return;
  const pageSize = 1000;
  const maxPasses = 50;
  // Always re-list from offset 0: removing objects shifts list indices.
  for (let pass = 0; pass < maxPasses; pass++) {
    const { data: files } = await admin.storage.from(bucket).list(folder, {
      limit: pageSize,
      offset: 0,
    });
    if (!files || files.length === 0) return;
    const nested = files.filter((f: { id?: string; name: string }) => !f.id);
    const objects = files
      .filter((f: { id?: string }) => f.id)
      .map((f: { name: string }) => `${folder}/${f.name}`);
    if (objects.length > 0) {
      const { error: rmErr } = await admin.storage.from(bucket).remove(objects);
      if (rmErr) throw rmErr;
    }
    for (const dir of nested) {
      await removeFolder(admin, bucket, `${folder}/${dir.name}`, maxDepth - 1);
    }
    if (files.length < pageSize) return;
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
