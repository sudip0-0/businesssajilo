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
          and current_role_name() in ('owner', 'sales', 'warehouse')
        order by b.created_at desc
        offset greatest(p_offset, 0)
        limit greatest(p_limit, 1)
      ) ranked
    ),
    '[]'::jsonb
  );
$$;
