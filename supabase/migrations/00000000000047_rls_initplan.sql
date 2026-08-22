drop policy if exists "staff reads audit log" on audit_log;
create policy "staff reads audit log" on audit_log for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
  );

drop policy if exists "staff read bill items" on bill_items;
create policy "staff read bill items" on bill_items for select using (
    bill_id in (
      select id from bills
      where business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales', 'warehouse')
    )
  );

drop policy if exists "staff read bills" on bills;
create policy "staff read bills" on bills for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
  );

drop policy if exists "members read own business" on businesses;
create policy "members read own business" on businesses for select using (id = (select current_business_id()));

drop policy if exists "owner updates business" on businesses;
create policy "owner updates business" on businesses for update using (id = (select current_business_id()) and (select current_role_name()) = 'owner');

drop policy if exists "customer reads own credit note items" on credit_note_items;
create policy "customer reads own credit note items" on credit_note_items for select using (
    exists (
      select 1 from credit_notes cn
      join customers c on c.id = cn.customer_id
      where cn.id = credit_note_id
        and cn.business_id = (select current_business_id())
        and (select current_role_name()) = 'customer'
        and c.member_id = (select current_member_id())
    )
  );

drop policy if exists "owner sales read credit note items" on credit_note_items;
create policy "owner sales read credit note items" on credit_note_items for select using (
    exists (
      select 1 from credit_notes cn
      where cn.id = credit_note_id
        and cn.business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales')
    )
  );

drop policy if exists "customer reads own credit notes" on credit_notes;
create policy "customer reads own credit notes" on credit_notes for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'customer'
    and customer_id in (
      select id from customers
      where member_id = (select current_member_id())
    )
  );

drop policy if exists "owner sales read credit notes" on credit_notes;
create policy "owner sales read credit notes" on credit_notes for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );

drop policy if exists "staff read own business balance projections" on customer_balance_projections;
create policy "staff read own business balance projections" on customer_balance_projections for select
  using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );

drop policy if exists "owner manages customers" on customers;
create policy "owner manages customers" on customers for all using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
  )
  with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
  );

drop policy if exists "sales reads customers" on customers;
create policy "sales reads customers" on customers for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'sales'
  );

drop policy if exists "warehouse reads customers" on customers;
create policy "warehouse reads customers" on customers for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'warehouse'
  );

drop policy if exists "members read co-members" on members;
create policy "members read co-members" on members for select using (business_id = (select current_business_id()));

drop policy if exists "owner updates co-members" on members;
create policy "owner updates co-members" on members for update using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
    and auth_user_id != auth.uid()
  )
  with check (business_id = (select current_business_id()));

drop policy if exists "recipient marks notifications read" on notifications;
create policy "recipient marks notifications read" on notifications for update using (
    business_id = (select current_business_id())
    and recipient_member_id = (select current_member_id())
  )
  with check (
    business_id = (select current_business_id())
    and recipient_member_id = (select current_member_id())
  );

drop policy if exists "recipient reads own notifications" on notifications;
create policy "recipient reads own notifications" on notifications for select using (
    business_id = (select current_business_id())
    and recipient_member_id = (select current_member_id())
  );

drop policy if exists "customer inserts own order items" on order_items;
create policy "customer inserts own order items" on order_items for insert with check (
    order_id in (
      select id from orders
      where customer_id = own_customer_id()
        and status = 'placed'
        and business_id = (select current_business_id())
    )
  );

drop policy if exists "staff read order items" on order_items;
create policy "staff read order items" on order_items for select using (
    order_id in (
      select id from orders where business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales', 'warehouse')
    )
  );

drop policy if exists "customer inserts own orders" on orders;
create policy "customer inserts own orders" on orders for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'customer'
    and customer_id = own_customer_id()
    and status = 'placed'
  );

drop policy if exists "customer reads own orders" on orders;
create policy "customer reads own orders" on orders for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'customer'
    and customer_id = own_customer_id()
  );

drop policy if exists "owner sales read orders" on orders;
create policy "owner sales read orders" on orders for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );

drop policy if exists "owner sales update orders" on orders;
create policy "owner sales update orders" on orders for update using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  )
  with check (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );

drop policy if exists "owner sales read payments" on payments;
create policy "owner sales read payments" on payments for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );

drop policy if exists "owner and sales manage products" on products;
create policy "owner and sales manage products" on products for all using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  )
  with check (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );

drop policy if exists "staff read active products" on products;
create policy "staff read active products" on products for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
    and (
      is_active
      or (select current_role_name()) in ('owner', 'sales')
    )
  );

drop policy if exists "owner sales manage quote items" on quote_items;
create policy "owner sales manage quote items" on quote_items for all using (
    quote_id in (
      select q.id from quotes q
      join orders o on o.id = q.order_id
      where o.business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales')
    )
  )
  with check (
    quote_id in (
      select q.id from quotes q
      join orders o on o.id = q.order_id
      where o.business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales')
    )
  );

drop policy if exists "owner sales manage quotes" on quotes;
create policy "owner sales manage quotes" on quotes for all using (
    order_id in (
      select id from orders
      where business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales')
    )
  )
  with check (
    order_id in (
      select id from orders
      where business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales')
    )
    and created_by = (select current_member_id())
  );

drop policy if exists "owner warehouse insert movements" on stock_movements;
create policy "owner warehouse insert movements" on stock_movements for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'warehouse')
    and created_by = (select current_member_id())
  );

drop policy if exists "staff read movements" on stock_movements;
create policy "staff read movements" on stock_movements for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
  );

drop policy if exists "owner delete product images" on storage.objects;
create policy "owner delete product images" on storage.objects for delete using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) = 'owner'
  );

drop policy if exists "owner update product images" on storage.objects;
create policy "owner update product images" on storage.objects for update using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) = 'owner'
  );

drop policy if exists "owner upload product images" on storage.objects;
create policy "owner upload product images" on storage.objects for insert with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) = 'owner'
  );

drop policy if exists "staff read product images" on storage.objects;
create policy "staff read product images" on storage.objects for select using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
  );