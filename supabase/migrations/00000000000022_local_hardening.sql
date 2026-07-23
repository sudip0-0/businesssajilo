-- Phase 22: local 95+ security/data contracts
-- - Credit notes RPC-only (drop direct INSERT policies)
-- - Align owner_dashboard_stats dues with total_dues (positive balances only)
-- - Bound messages.body length
-- - Revoke client execute on insert_audit_log (triggers/SECURITY DEFINER only)

-- ---------------------------------------------------------------------------
-- 1. Credit notes: RPC-only writes
-- ---------------------------------------------------------------------------

drop policy if exists "owner inserts credit notes" on credit_notes;
drop policy if exists "sales inserts credit notes" on credit_notes;
drop policy if exists "owner inserts credit note items" on credit_note_items;
drop policy if exists "sales inserts credit note items" on credit_note_items;

-- ---------------------------------------------------------------------------
-- 2. owner_dashboard_stats: dues = sum of positive balances only
-- ---------------------------------------------------------------------------

create or replace function owner_dashboard_stats()
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  with
  today as (
    select (timezone('Asia/Kathmandu', now()))::date as d
  ),
  sales as (
    select
      coalesce(sum(case when r.sale_date = t.d then r.total_sales else 0 end), 0)::bigint
        as today_sales,
      coalesce(sum(case when r.sale_date = (t.d - 1) then r.total_sales else 0 end), 0)::bigint
        as yesterday_sales
    from today t
    left join report_sales_daily r
      on r.sale_date in (t.d, t.d - 1)
     and r.business_id = current_business_id()
  ),
  dues as (
    select coalesce(sum(cb.balance_due), 0)::bigint as total_dues
    from customer_balances cb
    where cb.business_id = current_business_id()
      and cb.balance_due > 0
      and current_role_name() in ('owner', 'sales')
  ),
  low_stock as (
    select count(*)::int as low_stock_count
    from products p
    where p.business_id = current_business_id()
      and p.is_active = true
      and p.low_stock_threshold > 0
      and p.stock_cached <= p.low_stock_threshold
      and current_role_name() in ('owner', 'sales', 'warehouse')
  ),
  pending as (
    select count(*)::int as pending_orders
    from orders o
    where o.business_id = current_business_id()
      and o.status in ('placed', 'quoted', 'accepted')
      and current_role_name() in ('owner', 'sales', 'warehouse')
  )
  select jsonb_build_object(
    'today_sales', (select today_sales from sales),
    'yesterday_sales', (select yesterday_sales from sales),
    'total_dues', (select total_dues from dues),
    'low_stock_count', (select low_stock_count from low_stock),
    'pending_orders', (select pending_orders from pending)
  );
$$;

grant execute on function owner_dashboard_stats() to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Chat body length cap (4_000 characters)
-- ---------------------------------------------------------------------------

alter table messages
  drop constraint if exists messages_body_max_len;

alter table messages
  add constraint messages_body_max_len
  check (length(body) <= 4000);

-- ---------------------------------------------------------------------------
-- 4. Audit log: no direct client EXECUTE
-- ---------------------------------------------------------------------------

revoke execute on function insert_audit_log(
  text, uuid, text, text, text, audit_source
) from authenticated;
