-- Allow sales (in addition to owner) to manage products and see inactive ones.

drop policy if exists "staff read active products" on products;
create policy "staff read active products" on products
  for select using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales', 'warehouse')
    and (
      is_active
      or current_role_name() in ('owner', 'sales')
    )
  );

drop policy if exists "owner manages products" on products;
create policy "owner and sales manage products" on products
  for all using (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  )
  with check (
    business_id = current_business_id()
    and current_role_name() in ('owner', 'sales')
  );
