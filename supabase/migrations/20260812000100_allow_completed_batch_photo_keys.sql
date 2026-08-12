-- Completed batches remain immutable except for the deterministic photo object
-- reference. This permits delayed consent, retryable uploads, and revocation
-- without reopening any assessment or order edits.
create or replace function public.enforce_scan_rules()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  removes_from_old_batch boolean;
begin
  if old.deleted_at is not null and new.deleted_at is null then
    raise exception 'scan_restore_not_supported';
  end if;

  if old.deleted_at is null
    and new.deleted_at is null
    and old.remote_image_key is distinct from new.remote_image_key
    and new.batch_id is not distinct from old.batch_id
    and new.fruit_type is not distinct from old.fruit_type
    and new.ripeness_stage is not distinct from old.ripeness_stage
    and new.model_confidence is not distinct from old.model_confidence
    and new.model_version is not distinct from old.model_version
    and new.result_origin is not distinct from old.result_origin
    and new.shelf_life_status is not distinct from old.shelf_life_status
    and new.shelf_life_minimum is not distinct from old.shelf_life_minimum
    and new.shelf_life_maximum is not distinct from old.shelf_life_maximum
    and new.shelf_life_unit is not distinct from old.shelf_life_unit
    and new.shelf_life_guidance is not distinct from old.shelf_life_guidance
    and new.shelf_life_reason is not distinct from old.shelf_life_reason
    and new.shelf_life_evidence_version is not distinct from old.shelf_life_evidence_version
    and new.created_at is not distinct from old.created_at
    and new.updated_at is not distinct from old.updated_at
    and new.deleted_at is not distinct from old.deleted_at then
    return new;
  end if;

  removes_from_old_batch := old.batch_id is not null
    and old.deleted_at is null
    and (
      new.deleted_at is not null
      or new.batch_id is distinct from old.batch_id
    );

  if removes_from_old_batch and exists (
    select 1 from public.orders as order_row
    where order_row.user_id = old.user_id
      and order_row.batch_id = old.batch_id
      and order_row.deleted_at is null
      and order_row.status = 'completed'
  ) then
    raise exception 'completed_batch_locked';
  end if;

  if removes_from_old_batch and exists (
    select 1 from public.orders as order_row
    where order_row.user_id = old.user_id
      and order_row.batch_id = old.batch_id
      and order_row.deleted_at is null
      and order_row.status = 'pending'
  ) and not exists (
    select 1 from public.scan_records as remaining_scan
    where remaining_scan.user_id = old.user_id
      and remaining_scan.batch_id = old.batch_id
      and remaining_scan.id <> old.id
      and remaining_scan.deleted_at is null
  ) then
    raise exception 'pending_order_requires_scan';
  end if;

  if new.batch_id is not null and new.deleted_at is null and exists (
    select 1 from public.orders as order_row
    where order_row.user_id = new.user_id
      and order_row.batch_id = new.batch_id
      and order_row.deleted_at is null
      and order_row.status = 'completed'
  ) then
    raise exception 'completed_batch_locked';
  end if;

  return new;
end;
$$;
