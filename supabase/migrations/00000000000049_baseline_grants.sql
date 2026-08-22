-- 49: Baseline grants for auto_expose_new_tables = false.
--
-- With implicit exposure opted out, every table/view must grant explicitly.
-- This project's security model is RLS-only (FORCE ROW LEVEL SECURITY on all
-- tables, per-role policies), so the baseline grants full table privileges to
-- authenticated and SELECT on views — access is still decided entirely by
-- policy. Anything privileged beyond staff reach lives in SECURITY DEFINER
-- RPCs and is never granted at the table level.

grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on all tables in schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to service_role;
grant execute on function occurred_at_from_payload(jsonb) to authenticated;

-- bill_sequences stays unreadable by design (internal numbering); the
-- phase10 hardening revokes are re-applied after the blanket baseline.
revoke all on bill_sequences from authenticated, anon;

-- Future tables created by later migrations get the same baseline
-- automatically; policies remain the gate.
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated;
