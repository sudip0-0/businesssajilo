-- 48: Index for record_payment oldest-first allocation scan.
--
-- record_payment (allocate = 'oldest_first') scans:
--   bills WHERE customer_id = ? AND business_id = ? AND status IN ('due','partial')
--   ORDER BY created_at ASC
-- No index covered that predicate before; this composite matches it exactly.

create index if not exists bills_customer_status_created_idx
  on bills (business_id, customer_id, status, created_at);
