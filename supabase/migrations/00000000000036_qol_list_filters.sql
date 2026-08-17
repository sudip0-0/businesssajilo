-- QoL / optimization: unread notification index, local notify URL, and
-- paginated server-side list/search helpers.

create index if not exists notifications_unread_recipient_idx
  on notifications (recipient_member_id, created_at desc)
  where read_at is null;

create or replace function trigger_dispatch_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  notify_url text;
  service_key text;
begin
  if to_regprocedure('net.http_post(uuid,text,jsonb,jsonb,integer)') is null then
    return NEW;
  end if;

  notify_url := coalesce(
    current_setting('app.settings.notify_function_url', true),
    'http://host.docker.internal:55021/functions/v1/notify'
  );
  service_key := current_setting('app.settings.service_role_key', true);

  perform net.http_post(
    url := notify_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || coalesce(service_key, '')
    ),
    body := jsonb_build_object('notification_id', NEW.id)
  );

  return NEW;
exception
  when others then
    return NEW;
end;
$$;

create or replace function list_products_page(
  p_active_only boolean default true,
  p_query text default null,
  p_stock_filter text default 'all',
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
      select jsonb_agg(to_jsonb(p) order by p.name)
      from (
        select *
        from products prod
        where prod.business_id = current_business_id()
          and prod.is_active = p_active_only
          and (
            p_query is null
            or length(trim(p_query)) = 0
            or prod.name ilike '%' || trim(p_query) || '%'
            or coalesce(prod.sku, '') ilike '%' || trim(p_query) || '%'
            or coalesce(prod.name_np, '') ilike '%' || trim(p_query) || '%'
          )
          and (
            coalesce(p_stock_filter, 'all') = 'all'
            or (
              p_stock_filter = 'low'
              and prod.low_stock_threshold > 0
              and prod.stock_cached <= prod.low_stock_threshold
            )
            or (
              p_stock_filter = 'out'
              and prod.stock_cached <= 0
            )
            or (
              p_stock_filter = 'inStock'
              and prod.stock_cached > 0
              and (
                prod.low_stock_threshold <= 0
                or prod.stock_cached > prod.low_stock_threshold
              )
            )
          )
          and current_role_name() in ('owner', 'sales', 'warehouse')
        order by prod.name
        offset greatest(p_offset, 0)
        limit greatest(p_limit, 1)
      ) p
    ),
    '[]'::jsonb
  );
$$;

grant execute on function list_products_page(boolean, text, text, int, int) to authenticated;

create or replace function search_bills(
  p_query text default null,
  p_status bill_status default null,
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
                when c.id is null then null
                else jsonb_build_object('shop_name', c.shop_name)
              end,
              'members',
              case
                when m.id is null then null
                else jsonb_build_object('display_name', m.display_name, 'role', m.role)
              end
            ) as row_data
        from bills b
        left join customers c on c.id = b.customer_id
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
          and current_role_name() in ('owner', 'sales', 'warehouse')
        order by b.created_at desc
        offset greatest(p_offset, 0)
        limit greatest(p_limit, 1)
      ) ranked
    ),
    '[]'::jsonb
  );
$$;

grant execute on function search_bills(text, bill_status, timestamptz, timestamptz, int, int) to authenticated;
