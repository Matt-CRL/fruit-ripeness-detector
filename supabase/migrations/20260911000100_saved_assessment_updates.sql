alter table public.scan_records
  add column if not exists ripeness_update_source text,
  add column if not exists ripeness_updated_at timestamptz;

alter table public.scan_records
  drop constraint if exists scan_records_ripeness_update_source_check;

alter table public.scan_records
  add constraint scan_records_ripeness_update_source_check check (
    ripeness_update_source is null
    or ripeness_update_source in (
      'initial',
      'manual',
      'upload_rescan',
      'live_rescan'
    )
  );

alter table public.scan_records
  drop constraint if exists scan_records_ripeness_updated_at_check;

alter table public.scan_records
  add constraint scan_records_ripeness_updated_at_check check (
    ripeness_updated_at is null or ripeness_updated_at >= created_at
  );

update public.scan_records
set ripeness_update_source = case
      when lower(model_version) like '%(adjusted by user)%' then 'manual'
      else 'initial'
    end,
    ripeness_updated_at = case
      when lower(model_version) like '%(adjusted by user)%' then updated_at
      else created_at
    end
where ripeness_update_source is null
   or ripeness_updated_at is null;
