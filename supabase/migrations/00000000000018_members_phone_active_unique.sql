-- Soft-deactivated members should not block phone reuse forever.
-- Prefer reactivating an inactive member; uniqueness only among active rows.

drop index if exists members_phone_unique_idx;

create unique index members_phone_unique_idx
  on members(phone)
  where phone is not null and is_active;
