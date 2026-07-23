-- Phase 20: remove unused apply_product_sync.
-- Product create/edit is online-only (CachedProductsRepository delegates
-- writes to the remote Supabase client). The LWW merge RPC was never
-- called from Dart and is dropped to avoid a half-built offline path.

drop function if exists apply_product_sync(
  uuid, text, text, text, uuid, text, bigint, bigint, text, int, int, boolean, timestamptz
);
