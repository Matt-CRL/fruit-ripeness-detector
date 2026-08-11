create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_cron with schema extensions;

create table public.batches (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name varchar(120) not null check (length(btrim(name)) > 0),
  fruit_type text not null check (
    fruit_type in ('carabao_mango', 'lakatan_banana', 'red_papaya')
  ),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  revision bigint not null default 1 check (revision > 0),
  server_changed_at timestamptz not null default clock_timestamp(),
  constraint batches_timestamps_check check (
    updated_at >= created_at
    and (deleted_at is null or deleted_at >= created_at)
  ),
  constraint batches_owner_id_unique unique (user_id, id),
  constraint batches_owner_id_fruit_unique unique (user_id, id, fruit_type)
);

create table public.scan_records (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  batch_id uuid,
  fruit_type text not null check (
    fruit_type in ('carabao_mango', 'lakatan_banana', 'red_papaya')
  ),
  ripeness_stage text not null check (
    ripeness_stage in ('unripe', 'ripe', 'overripe')
  ),
  model_confidence double precision not null check (
    model_confidence >= 0 and model_confidence <= 1
  ),
  result_origin text not null check (
    result_origin in ('demo', 'on_device_model')
  ),
  shelf_life_status text not null check (
    shelf_life_status in ('available', 'unavailable')
  ),
  shelf_life_minimum integer,
  shelf_life_maximum integer,
  shelf_life_unit text,
  shelf_life_guidance text,
  shelf_life_reason text,
  shelf_life_evidence_version text not null
    check (length(btrim(shelf_life_evidence_version)) > 0),
  model_version varchar(120) not null check (length(btrim(model_version)) > 0),
  remote_image_key text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  revision bigint not null default 1 check (revision > 0),
  server_changed_at timestamptz not null default clock_timestamp(),
  constraint scan_records_batch_owner_fruit_fk foreign key (
    user_id,
    batch_id,
    fruit_type
  ) references public.batches (user_id, id, fruit_type) on delete cascade,
  constraint scan_records_shelf_life_check check (
    (
      shelf_life_status = 'available'
      and shelf_life_minimum is not null
      and shelf_life_minimum >= 0
      and shelf_life_maximum is not null
      and shelf_life_maximum >= shelf_life_minimum
      and shelf_life_unit is not null
      and length(btrim(shelf_life_unit)) > 0
      and shelf_life_guidance is not null
      and length(btrim(shelf_life_guidance)) > 0
      and shelf_life_reason is null
    )
    or
    (
      shelf_life_status = 'unavailable'
      and shelf_life_minimum is null
      and shelf_life_maximum is null
      and shelf_life_unit is null
      and shelf_life_guidance is null
      and shelf_life_reason is not null
      and length(btrim(shelf_life_reason)) > 0
    )
  ),
  constraint scan_records_remote_image_key_check check (
    remote_image_key is null
    or remote_image_key = user_id::text || '/' || id::text || '/history.jpg'
  ),
  constraint scan_records_timestamps_check check (
    updated_at >= created_at
    and (deleted_at is null or deleted_at >= created_at)
  )
);

create table public.orders (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  batch_id uuid not null,
  customer_name varchar(160) not null check (length(btrim(customer_name)) > 0),
  delivery_address varchar(500) not null
    check (length(btrim(delivery_address)) > 0),
  delivery_date timestamptz not null,
  status text not null check (status in ('pending', 'completed')),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  revision bigint not null default 1 check (revision > 0),
  server_changed_at timestamptz not null default clock_timestamp(),
  constraint orders_batch_owner_fk foreign key (user_id, batch_id)
    references public.batches (user_id, id) on delete cascade,
  constraint orders_timestamps_check check (
    updated_at >= created_at
    and (deleted_at is null or deleted_at >= created_at)
  )
);

create table public.user_settings (
  id uuid primary key,
  user_id uuid not null unique references auth.users (id) on delete cascade,
  image_upload_consent boolean not null default false,
  consent_version text not null check (length(btrim(consent_version)) > 0),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  revision bigint not null default 1 check (revision > 0),
  server_changed_at timestamptz not null default clock_timestamp(),
  constraint user_settings_timestamps_check check (
    updated_at >= created_at
    and (deleted_at is null or deleted_at >= created_at)
  )
);

create unique index orders_one_active_per_batch_idx
  on public.orders (user_id, batch_id)
  where deleted_at is null;
create index batches_user_active_idx
  on public.batches (user_id, deleted_at, created_at, id);
create index batches_server_changes_idx
  on public.batches (server_changed_at, id);
create index scan_records_user_active_idx
  on public.scan_records (user_id, deleted_at, created_at, id);
create index scan_records_batch_active_idx
  on public.scan_records (user_id, batch_id, deleted_at, created_at, id);
create index scan_records_server_changes_idx
  on public.scan_records (server_changed_at, id);
create index orders_user_active_idx
  on public.orders (user_id, deleted_at, updated_at, id);
create index orders_server_changes_idx
  on public.orders (server_changed_at, id);
create index user_settings_server_changes_idx
  on public.user_settings (server_changed_at, id);

create or replace function public.set_server_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.revision := 1;
    new.server_changed_at := clock_timestamp();
    return new;
  end if;

  if new.id is distinct from old.id
    or new.user_id is distinct from old.user_id
    or new.created_at is distinct from old.created_at then
    raise exception 'immutable_remote_identity';
  end if;

  new.revision := old.revision + 1;
  new.server_changed_at := clock_timestamp();
  return new;
end;
$$;

create or replace function public.enforce_batch_rules()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.deleted_at is not null and new.deleted_at is null then
    raise exception 'batch_restore_not_supported';
  end if;

  if exists (
    select 1
    from public.orders as order_row
    where order_row.user_id = old.user_id
      and order_row.batch_id = old.id
      and order_row.deleted_at is null
      and order_row.status = 'completed'
  ) and (
    new.name is distinct from old.name
    or new.fruit_type is distinct from old.fruit_type
    or new.deleted_at is distinct from old.deleted_at
  ) then
    raise exception 'completed_batch_locked';
  end if;

  if old.deleted_at is null and new.deleted_at is not null then
    if exists (
      select 1 from public.scan_records as scan_row
      where scan_row.user_id = old.user_id
        and scan_row.batch_id = old.id
        and scan_row.deleted_at is null
    ) then
      raise exception 'active_batch_scans_exist';
    end if;
    if exists (
      select 1 from public.orders as order_row
      where order_row.user_id = old.user_id
        and order_row.batch_id = old.id
        and order_row.deleted_at is null
    ) then
      raise exception 'active_batch_order_exists';
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.enforce_settings_rules()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.deleted_at is not null and new.deleted_at is null then
    raise exception 'settings_restore_not_supported';
  end if;

  if new.deleted_at is not null and new.image_upload_consent then
    raise exception 'deleted_settings_cannot_consent';
  end if;

  return new;
end;
$$;

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

create or replace function public.enforce_order_rules()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    if old.deleted_at is not null and new.deleted_at is null then
      raise exception 'order_restore_not_supported';
    end if;

    if new.batch_id is distinct from old.batch_id then
      raise exception 'order_batch_is_immutable';
    end if;

    if old.status = 'completed'
      and new.deleted_at is null
      and (
        new.customer_name is distinct from old.customer_name
        or new.delivery_address is distinct from old.delivery_address
        or new.delivery_date is distinct from old.delivery_date
        or new.status is distinct from old.status
      ) then
      raise exception 'completed_order_locked';
    end if;
  end if;

  if new.deleted_at is null then
    if not exists (
      select 1 from public.batches as batch_row
      where batch_row.user_id = new.user_id
        and batch_row.id = new.batch_id
        and batch_row.deleted_at is null
    ) then
      raise exception 'order_requires_active_batch';
    end if;

    if not exists (
      select 1 from public.scan_records as scan_row
      where scan_row.user_id = new.user_id
        and scan_row.batch_id = new.batch_id
        and scan_row.deleted_at is null
    ) then
      raise exception 'order_requires_nonempty_batch';
    end if;
  end if;

  return new;
end;
$$;

create trigger batches_rules_before_update
before update on public.batches
for each row execute function public.enforce_batch_rules();
create trigger batches_revision_before_write
before insert or update on public.batches
for each row execute function public.set_server_revision();

create trigger scan_records_rules_before_update
before update on public.scan_records
for each row execute function public.enforce_scan_rules();
create trigger scan_records_revision_before_write
before insert or update on public.scan_records
for each row execute function public.set_server_revision();

create trigger orders_rules_before_write
before insert or update on public.orders
for each row execute function public.enforce_order_rules();
create trigger orders_revision_before_write
before insert or update on public.orders
for each row execute function public.set_server_revision();

create trigger user_settings_revision_before_write
before insert or update on public.user_settings
for each row execute function public.set_server_revision();
create trigger user_settings_rules_before_update
before update on public.user_settings
for each row execute function public.enforce_settings_rules();

alter table public.batches enable row level security;
alter table public.scan_records enable row level security;
alter table public.orders enable row level security;
alter table public.user_settings enable row level security;

create policy batches_owner_select on public.batches
for select to authenticated
using ((select auth.uid()) = user_id);
create policy batches_owner_insert on public.batches
for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy batches_owner_update on public.batches
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy scans_owner_select on public.scan_records
for select to authenticated
using ((select auth.uid()) = user_id);
create policy scans_owner_insert on public.scan_records
for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy scans_owner_update on public.scan_records
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy orders_owner_select on public.orders
for select to authenticated
using ((select auth.uid()) = user_id);
create policy orders_owner_insert on public.orders
for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy orders_owner_update on public.orders
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy settings_owner_select on public.user_settings
for select to authenticated
using ((select auth.uid()) = user_id);
create policy settings_owner_insert on public.user_settings
for insert to authenticated
with check ((select auth.uid()) = user_id);
create policy settings_owner_update on public.user_settings
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on public.batches from anon, authenticated;
revoke all on public.scan_records from anon, authenticated;
revoke all on public.orders from anon, authenticated;
revoke all on public.user_settings from anon, authenticated;
grant select, insert, update on public.batches to authenticated;
grant select, insert, update on public.scan_records to authenticated;
grant select, insert, update on public.orders to authenticated;
grant select, insert, update on public.user_settings to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('scan-images', 'scan-images', false, 5242880, array['image/jpeg'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy scan_images_owner_select on storage.objects
for select to authenticated
using (
  bucket_id = 'scan-images'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

create policy scan_images_owner_insert on storage.objects
for insert to authenticated
with check (
  bucket_id = 'scan-images'
  and split_part(name, '/', 1) = (select auth.uid())::text
  and split_part(name, '/', 2) ~
    '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  and split_part(name, '/', 3) = 'history.jpg'
  and split_part(name, '/', 4) = ''
  and exists (
    select 1 from public.user_settings as setting
    where setting.user_id = (select auth.uid())
      and setting.image_upload_consent
      and setting.deleted_at is null
  )
);

create policy scan_images_owner_update on storage.objects
for update to authenticated
using (
  bucket_id = 'scan-images'
  and split_part(name, '/', 1) = (select auth.uid())::text
)
with check (
  bucket_id = 'scan-images'
  and split_part(name, '/', 1) = (select auth.uid())::text
  and split_part(name, '/', 2) ~
    '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  and split_part(name, '/', 3) = 'history.jpg'
  and split_part(name, '/', 4) = ''
  and exists (
    select 1 from public.user_settings as setting
    where setting.user_id = (select auth.uid())
      and setting.image_upload_consent
      and setting.deleted_at is null
  )
);

create policy scan_images_owner_delete on storage.objects
for delete to authenticated
using (
  bucket_id = 'scan-images'
  and split_part(name, '/', 1) = (select auth.uid())::text
);

create or replace function public.sync_anchor()
returns timestamptz
language sql
stable
set search_path = ''
as $$
  select clock_timestamp();
$$;

revoke all on function public.sync_anchor() from public, anon;
grant execute on function public.sync_anchor() to authenticated;

create or replace function public.purge_expired_tombstones()
returns table (
  orders_deleted bigint,
  scans_deleted bigint,
  batches_deleted bigint,
  settings_deleted bigint
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  order_count bigint;
  scan_count bigint;
  batch_count bigint;
  settings_count bigint;
begin
  delete from public.orders
  where deleted_at < clock_timestamp() - interval '30 days';
  get diagnostics order_count = row_count;

  delete from public.scan_records
  where deleted_at < clock_timestamp() - interval '30 days'
    and remote_image_key is null;
  get diagnostics scan_count = row_count;

  delete from public.batches
  where deleted_at < clock_timestamp() - interval '30 days'
    and not exists (
      select 1 from public.scan_records as scan_row
      where scan_row.user_id = batches.user_id
        and scan_row.batch_id = batches.id
    )
    and not exists (
      select 1 from public.orders as order_row
      where order_row.user_id = batches.user_id
        and order_row.batch_id = batches.id
    );
  get diagnostics batch_count = row_count;

  delete from public.user_settings
  where deleted_at < clock_timestamp() - interval '30 days';
  get diagnostics settings_count = row_count;

  return query select order_count, scan_count, batch_count, settings_count;
end;
$$;

revoke all on function public.purge_expired_tombstones() from public, anon, authenticated;
grant execute on function public.purge_expired_tombstones() to service_role;

select cron.schedule(
  'kami-purge-tombstones',
  '17 3 * * *',
  'select public.purge_expired_tombstones()'
);
