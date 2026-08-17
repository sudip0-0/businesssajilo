-- Benchmark customer_balances vs customer_balance_projections.
-- Run against a production-like copy after migration 37:
--   psql "$DATABASE_URL" -f scripts/benchmark_customer_balances.sql
--
-- Gate for switching live reads:
--   p95 customer list < 200ms AND projection_drift count = 0
-- Keep customer_balances as the rollback path until then.

\timing on

explain (analyze, buffers)
select count(*) from customer_balances
where business_id = 'e2e00000-0000-4000-8000-000000000010'
  and balance_due > 0;

explain (analyze, buffers)
select count(*) from customer_balance_projections
where business_id = 'e2e00000-0000-4000-8000-000000000010'
  and balance_due > 0;

select count(*) as drift_rows from customer_balance_projection_drift;
