begin;

select plan(24);

select has_table('public', 'batches', 'batches table exists');
select has_table('public', 'scan_records', 'scan_records table exists');
select has_table('public', 'orders', 'orders table exists');
select has_table('public', 'user_settings', 'user_settings table exists');

select col_is_pk('public', 'batches', 'id', 'batches use client UUIDs');
select col_is_pk('public', 'scan_records', 'id', 'scans use client UUIDs');
select col_is_pk('public', 'orders', 'id', 'orders use client UUIDs');
select col_is_pk(
  'public',
  'user_settings',
  'id',
  'settings use a client UUID'
);

select has_column('public', 'batches', 'revision', 'batches carry revisions');
select has_column(
  'public',
  'scan_records',
  'remote_image_key',
  'scan rows carry private object keys'
);
select has_column('public', 'orders', 'deleted_at', 'orders use tombstones');
select has_column(
  'public',
  'user_settings',
  'image_upload_consent',
  'settings carry image consent'
);
select has_column(
  'public',
  'user_settings',
  'deleted_at',
  'settings use tombstones'
);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.batches'::regclass),
  'batches enable RLS'
);
select ok(
  (
    select relrowsecurity
    from pg_class
    where oid = 'public.scan_records'::regclass
  ),
  'scan_records enable RLS'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.orders'::regclass),
  'orders enable RLS'
);
select ok(
  (
    select relrowsecurity
    from pg_class
    where oid = 'public.user_settings'::regclass
  ),
  'user_settings enable RLS'
);

select ok(
  (
    select count(*) = 3
    from pg_policies
    where schemaname = 'public' and tablename = 'batches'
  ),
  'batches expose owner-only select/insert/update policies'
);
select ok(
  (
    select count(*) = 3
    from pg_policies
    where schemaname = 'public' and tablename = 'scan_records'
  ),
  'scans expose owner-only select/insert/update policies'
);
select ok(
  (
    select count(*) = 3
    from pg_policies
    where schemaname = 'public' and tablename = 'orders'
  ),
  'orders expose owner-only select/insert/update policies'
);
select ok(
  (
    select count(*) = 3
    from pg_policies
    where schemaname = 'public' and tablename = 'user_settings'
  ),
  'settings expose owner-only select/insert/update policies'
);

select ok(
  exists (
    select 1 from storage.buckets
    where id = 'scan-images'
      and not public
      and file_size_limit = 5242880
      and allowed_mime_types = array['image/jpeg']
  ),
  'scan-images is private and JPEG constrained'
);
select ok(
  (
    select count(*) = 4
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname like 'scan_images_owner_%'
  ),
  'Storage exposes owner-scoped CRUD policies'
);
select ok(
  exists (
    select 1 from cron.job where jobname = 'kami-purge-tombstones'
  ),
  'daily tombstone cleanup is scheduled'
);

select * from finish();
rollback;
