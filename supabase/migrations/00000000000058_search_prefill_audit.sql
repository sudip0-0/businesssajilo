-- Customer own-bill search, warehouse billing-draft reads, and audit-log
-- financial isolation. Warehouse keeps identity-only billing and still cannot
-- read raw orders, quotes, or customer finance.

create or replace function public.search_bills(
  p_query text default null,
  p_status public.bill_status default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_offset int default 0,
  p_limit int default 50
)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce(
    (
      select jsonb_agg(row_data)
      from (
        select
          to_jsonb(b)
            || jsonb_build_object(
              'customers',
              case
                when c.customer_id is null then null
                else jsonb_build_object('shop_name', c.shop_name)
              end,
              'members',
              case
                when m.id is null then null
                else jsonb_build_object('display_name', m.display_name, 'role', m.role)
              end
            ) as row_data
        from bills b
        left join customer_directory c on c.customer_id = b.customer_id
        left join members m on m.id = b.created_by
        where b.business_id = current_business_id()
          and (p_status is null or b.status = p_status)
          and (p_from is null or b.created_at >= p_from)
          and (p_to is null or b.created_at < p_to)
          and (
            p_query is null
            or length(trim(p_query)) = 0
            or b.bill_no ilike '%' || trim(p_query) || '%'
            or coalesce(b.guest_name, '') ilike '%' || trim(p_query) || '%'
            or coalesce(c.shop_name, '') ilike '%' || trim(p_query) || '%'
          )
          and (
            current_role_name() in ('owner', 'sales', 'warehouse')
            or (
              current_role_name() = 'customer'
              and b.customer_id = own_customer_id()
            )
          )
        order by b.created_at desc
        offset greatest(p_offset, 0)
        limit greatest(p_limit, 1)
      ) ranked
    ),
    '[]'::jsonb
  );
$$;

create or replace function public.billing_draft_from_order(p_order_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_role text := current_role_name();
  v_business uuid := current_business_id();
  v_order public.orders%rowtype;
  v_shop text;
  v_quote_id uuid;
  v_lines jsonb;
begin
  if v_role is null or v_role not in ('owner', 'sales', 'warehouse') then
    raise exception 'forbidden';
  end if;
  if p_order_id is null or v_business is null then
    raise exception 'order not found';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id and business_id = v_business;
  if not found then
    raise exception 'order not found';
  end if;
  if v_order.status = 'billed' then
    raise exception 'order already billed';
  end if;

  select shop_name into v_shop
  from public.customer_directory
  where customer_id = v_order.customer_id;

  select q.id into v_quote_id
  from public.quotes q
  where q.order_id = v_order.id
    and q.business_id = v_business
    and q.status = 'accepted'
  order by q.version desc
  limit 1;

  if v_quote_id is not null then
    select coalesce(jsonb_agg(line order by ord), '[]'::jsonb)
    into v_lines
    from (
      select jsonb_build_object(
        'product_id', qi.product_id,
        'name_snapshot', coalesce(p.name, ''),
        'qty', qi.qty,
        'rate', qi.rate,
        'discount', qi.discount,
        'line_total', qi.line_total
      ) as line,
      qi.product_id::text as ord
      from public.quote_items qi
      left join public.products p on p.id = qi.product_id
      where qi.quote_id = v_quote_id
        and qi.business_id = v_business
    ) quoted;
    return jsonb_build_object(
      'order_id', v_order.id,
      'customer_id', v_order.customer_id,
      'shop_name', v_shop,
      'source', 'accepted_quote',
      'lines', v_lines
    );
  end if;

  select coalesce(jsonb_agg(line order by ord), '[]'::jsonb)
  into v_lines
  from (
    select jsonb_build_object(
      'product_id', oi.product_id,
      'name_snapshot', coalesce(oi.product_name, p.name, ''),
      'qty', oi.qty,
      'rate', coalesce(p.reference_price, 0),
      'discount', 0,
      'line_total', (oi.qty::bigint * coalesce(p.reference_price, 0))
    ) as line,
    oi.product_id::text as ord
    from public.order_items oi
    left join public.products p on p.id = oi.product_id
    where oi.order_id = v_order.id
      and oi.business_id = v_business
  ) unordered;

  return jsonb_build_object(
    'order_id', v_order.id,
    'customer_id', v_order.customer_id,
    'shop_name', v_shop,
    'source', 'order_items',
    'lines', v_lines
  );
end;
$$;

revoke all on function public.billing_draft_from_order(uuid) from public, anon;
grant execute on function public.billing_draft_from_order(uuid) to authenticated;

drop policy if exists "staff reads audit log" on public.audit_log;
create policy "staff reads audit log" on public.audit_log for select using (
    business_id = (select current_business_id())
    and (select current_role_name()) in ('owner', 'sales')
  );

notify pgrst, 'reload schema';
