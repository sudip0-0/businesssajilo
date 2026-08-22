alter policy "staff reads audit log" on audit_log body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
  );;

alter policy "owner inserts bill items" on bill_items body for insert with check (
    bill_id in (
      select id from bills
      where business_id = (select current_business_id())
        and (select current_role_name()) = 'owner'
        and created_by = (select current_member_id())
    )
  );;

alter policy "owner sales read bill items" on bill_items body for select using (
    bill_id in (
      select id from bills
      where business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales')
    )
  );;

alter policy "sales inserts bill items" on bill_items body for insert with check (
    bill_id in (
      select id from bills
      where business_id = (select current_business_id())
        and (select current_role_name()) = 'sales'
        and created_by = (select current_member_id())
    )
  );;

alter policy "staff read bill items" on bill_items body for select using (
    bill_id in (
      select id from bills
      where business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales', 'warehouse')
    )
  );;

alter policy "owner inserts bills" on bills body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
    and created_by = (select current_member_id())
  );;

alter policy "owner sales read bills" on bills body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "sales inserts bills" on bills body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'sales'
    and created_by = (select current_member_id())
  );;

alter policy "staff read bills" on bills body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
  );;

alter policy "members read own business" on businesses body for select using (id = (select current_business_id()));;

alter policy "owner updates business" on businesses body for update using (id = (select current_business_id()) and (select current_role_name()) = 'owner');;

alter policy "customer reads categories" on categories body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'customer'
  );;

alter policy "owner manages categories" on categories body for all using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
  )
  with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
  );;

alter policy "staff read categories" on categories body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
  );;

alter policy "customer reads own credit note items" on credit_note_items body for select using (
    exists (
      select 1 from credit_notes cn
      join customers c on c.id = cn.customer_id
      where cn.id = credit_note_id
        and cn.business_id = (select current_business_id())
        and (select current_role_name()) = 'customer'
        and c.member_id = (select current_member_id())
    )
  );;

alter policy "owner inserts credit note items" on credit_note_items body for insert with check (
    exists (
      select 1 from credit_notes cn
      where cn.id = credit_note_id
        and cn.business_id = (select current_business_id())
        and (select current_role_name()) = 'owner'
        and cn.created_by = (select current_member_id())
    )
  );;

alter policy "owner sales read credit note items" on credit_note_items body for select using (
    exists (
      select 1 from credit_notes cn
      where cn.id = credit_note_id
        and cn.business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales')
    )
  );;

alter policy "sales inserts credit note items" on credit_note_items body for insert with check (
    exists (
      select 1 from credit_notes cn
      where cn.id = credit_note_id
        and cn.business_id = (select current_business_id())
        and (select current_role_name()) = 'sales'
        and cn.created_by = (select current_member_id())
    )
  );;

alter policy "customer reads own credit notes" on credit_notes body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'customer'
    and customer_id in (
      select id from customers
      where member_id = (select current_member_id())
    )
  );;

alter policy "owner inserts credit notes" on credit_notes body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
    and created_by = (select current_member_id())
  );;

alter policy "owner sales read credit notes" on credit_notes body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "sales inserts credit notes" on credit_notes body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'sales'
    and created_by = (select current_member_id())
  );;

alter policy "staff read own business balance projections" on customer_balance_projections body for select
  using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "owner manages customers" on customers body for all using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
  )
  with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
  );;

alter policy "sales reads customers" on customers body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'sales'
  );;

alter policy "warehouse reads customers" on customers body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'warehouse'
  );;

alter policy "members read co-members" on members body for select using (business_id = (select current_business_id()));;

alter policy "owner updates co-members" on members body for update using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
    and auth_user_id != auth.uid()
  )
  with check (business_id = (select current_business_id()));;

alter policy "customer inserts own order messages" on messages body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'customer'
    and sender_member_id = (select current_member_id())
    and order_id in (
      select id from orders where customer_id = own_customer_id()
    )
  );;

alter policy "owner sales insert order messages" on messages body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
    and sender_member_id = (select current_member_id())
    and order_id in (
      select id from orders where business_id = (select current_business_id())
    )
  );;

alter policy "owner sales read order messages" on messages body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "recipient marks notifications read" on notifications body for update using (
    business_id = (select current_business_id())
    and recipient_member_id = (select current_member_id())
  )
  with check (
    business_id = (select current_business_id())
    and recipient_member_id = (select current_member_id())
  );;

alter policy "recipient reads own notifications" on notifications body for select using (
    business_id = (select current_business_id())
    and recipient_member_id = (select current_member_id())
  );;

alter policy "customer inserts own order items" on order_items body for insert with check (
    order_id in (
      select id from orders
      where customer_id = own_customer_id()
        and status = 'placed'
        and business_id = (select current_business_id())
    )
  );;

alter policy "staff read order items" on order_items body for select using (
    order_id in (
      select id from orders where business_id = (select current_business_id())
        and (select current_role_name()) in ('owner', 'sales', 'warehouse')
    )
  );;

alter policy "customer inserts own orders" on orders body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'customer'
    and customer_id = own_customer_id()
    and status = 'placed'
  );;

alter policy "customer reads own orders" on orders body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'customer'
    and customer_id = own_customer_id()
  );;

alter policy "owner sales read orders" on orders body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "owner sales update orders" on orders body for update using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  )
  with check (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "warehouse reads fulfillment orders" on orders body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'warehouse'
    and status in ('confirmed', 'packed', 'dispatched')
  );;

alter policy "warehouse updates fulfillment orders" on orders body for update using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'warehouse'
    and status in ('confirmed', 'packed')
  )
  with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'warehouse'
    and status in ('packed', 'dispatched')
  );;

alter policy "owner inserts payments" on payments body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
    and received_by = (select current_member_id())
  );;

alter policy "owner sales read payments" on payments body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "sales inserts payments" on payments body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'sales'
    and received_by = (select current_member_id())
  );;

alter policy "owner and sales manage products" on products body for all using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  )
  with check (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "owner manages products" on products body for all using (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
  )
  with check (
    business_id = (select current_business_id())
    and (select current_role_name()) = 'owner'
  );;

alter policy "staff read active products" on products body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
    and (
      is_active
      or (select current_role_name()) in ('owner', 'sales')
    )
  );;

alter policy "owner sales manage quote items" on quote_items body for all using (
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
  );;

alter policy "owner sales manage quotes" on quotes body for all using (
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
  );;

alter policy "owner warehouse insert movements" on stock_movements body for insert with check (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'warehouse')
    and created_by = (select current_member_id())
  );;

alter policy "staff read movements" on stock_movements body for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
  );;

alter policy "chat participants read images" on storage.objects body for select using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) in ('owner', 'sales', 'customer')
  );;

alter policy "chat participants upload images" on storage.objects body for insert with check (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) in ('owner', 'sales', 'customer')
    and (storage.foldername(name))[2] in (
      select id::text from orders where business_id = (select current_business_id())
    )
  );;

alter policy "customer delete own order chat images" on storage.objects body for delete using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) = 'customer'
    and (storage.foldername(name))[2] in (
      select id::text from orders where customer_id = own_customer_id()
    )
  );;

alter policy "customer read own order chat images" on storage.objects body for select using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) = 'customer'
    and (storage.foldername(name))[2] in (
      select id::text from orders where customer_id = own_customer_id()
    )
  );;

alter policy "customer upload own order chat images" on storage.objects body for insert with check (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) = 'customer'
    and (storage.foldername(name))[2] in (
      select id::text from orders where customer_id = own_customer_id()
    )
  );;

alter policy "owner delete product images" on storage.objects body for delete using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) = 'owner'
  );;

alter policy "owner update product images" on storage.objects body for update using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) = 'owner'
  );;

alter policy "owner upload product images" on storage.objects body for insert with check (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) = 'owner'
  );;

alter policy "staff delete chat images" on storage.objects body for delete using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "staff read chat images" on storage.objects body for select using (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) in ('owner', 'sales')
  );;

alter policy "staff read product images" on storage.objects body for select using (
    bucket_id = 'product-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) in ('owner', 'sales', 'warehouse')
  );;

alter policy "staff upload chat images" on storage.objects body for insert with check (
    bucket_id = 'order-chat-images'
    and (storage.foldername(name))[1] = (select current_business_id())::text
    and (select current_role_name()) in ('owner', 'sales')
    and (storage.foldername(name))[2] in (
      select id::text from orders where business_id = (select current_business_id())
    )
  );;
