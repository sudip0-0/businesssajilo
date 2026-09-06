create or replace function guard_customer_quote_response()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order orders%rowtype;
begin
  if current_role_name() = 'customer' then
    if (to_jsonb(new) - 'status' - 'response_comment') is distinct from
       (to_jsonb(old) - 'status' - 'response_comment') then
      raise exception 'quote response cannot change quote terms';
    end if;
    select * into v_order from orders where id = old.order_id for update;
    if v_order.customer_id is distinct from own_customer_id()
       or v_order.business_id is distinct from current_business_id() then
      raise exception 'forbidden';
    end if;
    if old.status <> 'sent' or new.status not in ('accepted', 'rejected') then
      raise exception 'quote is no longer awaiting a response';
    end if;
    if v_order.status not in ('placed', 'received') then
      raise exception 'order can no longer receive a quote response';
    end if;
    if old.expires_at is not null and old.expires_at <= clock_timestamp() then
      raise exception 'quote has expired';
    end if;
    if new.status = 'rejected' and nullif(btrim(new.response_comment), '') is null then
      raise exception 'rejection comment is required';
    end if;
  end if;
  return new;
end;
$$;
create trigger quotes_guard_customer_response before update on quotes
for each row execute function guard_customer_quote_response();

create or replace function respond_quote(p_quote_id uuid, p_status text, p_comment text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_order orders%rowtype;
  v_quote quotes%rowtype;
begin
  if current_role_name() is distinct from 'customer' then raise exception 'forbidden'; end if;
  if p_status is null or p_status not in ('accepted', 'rejected') then
    raise exception 'invalid quote response';
  end if;
  select order_id into v_order_id from quotes where id = p_quote_id;
  select * into v_order from orders where id = v_order_id for update;
  if not found or v_order.customer_id is distinct from own_customer_id()
     or v_order.business_id is distinct from current_business_id() then
    raise exception 'forbidden';
  end if;
  select * into v_quote from quotes where id = p_quote_id for update;
  if v_quote.status::text = p_status and v_quote.response_comment is not distinct from p_comment then
    return to_jsonb(v_quote);
  end if;
  update quotes set status = p_status::quote_status, response_comment = p_comment
    where id = p_quote_id returning * into v_quote;
  return to_jsonb(v_quote);
end;
$$;
revoke all on function respond_quote(uuid, text, text) from public, anon;
grant execute on function respond_quote(uuid, text, text) to authenticated;
