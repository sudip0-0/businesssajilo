create or replace function resolve_billing_customer(p jsonb)
returns uuid
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_raw text;
  v_id uuid;
  v_phone text;
  v_shop text;
  v_resolved uuid;
  v_matches uuid[];
  v_biz uuid := current_business_id();
begin
  v_raw := nullif(btrim(coalesce(p->>'customer_id', '')), '');
  v_phone := nullif(btrim(coalesce(p->>'customer_phone', '')), '');
  v_shop := nullif(btrim(coalesce(p->>'customer_shop_name', '')), '');
  if v_raw is null then
    if v_phone is not null or v_shop is not null then
      raise exception 'customer not found';
    end if;
    return null;
  end if;
  begin
    v_id := v_raw::uuid;
  exception when invalid_text_representation then
    raise exception 'customer not found';
  end;

  select c.id into v_resolved from customers c
  where c.id = v_id and c.business_id = v_biz;
  if v_resolved is not null then
    return v_resolved;
  end if;

  if v_phone is not null then
    select array_agg(c.id) into v_matches from customers c
    where c.business_id = v_biz and c.phone = v_phone;
    if cardinality(v_matches) = 1 then
      return v_matches[1];
    elsif cardinality(v_matches) > 1 then
      raise exception 'ambiguous customer phone';
    end if;
  end if;

  if v_shop is not null then
    select array_agg(c.id) into v_matches from customers c
    where c.business_id = v_biz and lower(c.shop_name) = lower(v_shop);
    if cardinality(v_matches) = 1 then
      return v_matches[1];
    elsif cardinality(v_matches) > 1 then
      raise exception 'ambiguous customer name';
    end if;
  end if;
  raise exception 'customer not found';
end;
$$;

revoke all on function resolve_billing_customer(jsonb) from public, anon, authenticated;
