drop policy if exists "warehouse reads customers" on public.customers;

create or replace view public.customer_directory
with (security_invoker = false, security_barrier = true)
as
select
  c.id as customer_id,
  c.business_id,
  c.member_id,
  c.shop_name,
  c.contact_name,
  c.phone,
  c.address,
  c.created_at,
  c.updated_at
from public.customers c
where c.business_id = (select public.current_business_id())
  and (
    (select public.current_role_name()) in ('owner', 'sales', 'warehouse')
    or (
      (select public.current_role_name()) = 'customer'
      and c.member_id = (select public.current_member_id())
    )
  );

revoke all on public.customer_directory from public, anon, authenticated;
grant select on public.customer_directory to authenticated;

notify pgrst, 'reload schema';
