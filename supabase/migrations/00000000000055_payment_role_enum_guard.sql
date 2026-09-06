do $$
declare
  definition text := pg_get_functiondef('public.record_payment(jsonb)'::regprocedure);
begin
  if position('coalesce(current_role_name(), '''')' in definition) = 0 then
    raise exception 'record_payment role guard not found';
  end if;
  execute replace(definition, 'coalesce(current_role_name(), '''')', 'coalesce(current_role_name()::text, '''')');
end;
$$;
