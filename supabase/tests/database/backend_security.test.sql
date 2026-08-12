begin;

select plan(20);

insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data
)
values
  (
    '11111111-1111-4111-8111-111111111111',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'owner-one@example.test',
    crypt('OwnerPassword1', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}'
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'owner-two@example.test',
    crypt('OwnerPassword2', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}'
  );

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
  true
);

select lives_ok(
  $$
    insert into public.batches (
      id, user_id, name, fruit_type, created_at, updated_at
    ) values (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      '11111111-1111-4111-8111-111111111111',
      'Owner batch',
      'carabao_mango',
      '2026-08-10T00:00:00Z',
      '2026-08-10T00:00:00Z'
    )
  $$,
  'an account can create its own batch'
);

select throws_ok(
  $$
    insert into public.batches (
      id, user_id, name, fruit_type, created_at, updated_at
    ) values (
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      '22222222-2222-4222-8222-222222222222',
      'Cross-account batch',
      'red_papaya',
      '2026-08-10T00:00:00Z',
      '2026-08-10T00:00:00Z'
    )
  $$,
  '42501',
  null,
  'RLS rejects a cross-account insert'
);

select is(
  (select count(*)::integer from public.batches),
  1,
  'an account sees only its own batch'
);

update public.batches
set name = 'Owner batch revised', updated_at = '2026-08-10T00:01:00Z'
where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and revision = 1;

select is(
  (
    select revision
    from public.batches
    where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  ),
  2::bigint,
  'accepted updates increment the server revision'
);

with stale_update as (
  update public.batches
  set name = 'Stale overwrite', updated_at = '2026-08-10T00:02:00Z'
  where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and revision = 1
  returning 1
)
select is(
  (select count(*)::integer from stale_update),
  0,
  'a stale expected revision cannot overwrite the accepted row'
);

select lives_ok(
  $$
    insert into public.user_settings (
      id,
      user_id,
      image_upload_consent,
      consent_version,
      created_at,
      updated_at
    ) values (
      '11111111-1111-4111-8111-111111111111',
      '11111111-1111-4111-8111-111111111111',
      false,
      'development-draft-v1',
      '2026-08-10T00:00:00Z',
      '2026-08-10T00:00:00Z'
    )
  $$,
  'an account can create its own consent setting'
);

select throws_ok(
  $$
    insert into storage.objects (bucket_id, name)
    values (
      'scan-images',
      '11111111-1111-4111-8111-111111111111/cccccccc-cccc-4ccc-8ccc-cccccccccccc/history.jpg'
    )
  $$,
  '42501',
  null,
  'Storage rejects uploads without image consent'
);

update public.user_settings
set image_upload_consent = true, updated_at = '2026-08-10T00:01:00Z'
where user_id = '11111111-1111-4111-8111-111111111111';

select lives_ok(
  $$
    insert into storage.objects (bucket_id, name)
    values (
      'scan-images',
      '11111111-1111-4111-8111-111111111111/cccccccc-cccc-4ccc-8ccc-cccccccccccc/history.jpg'
    )
  $$,
  'Storage permits an owner path after image consent'
);

update public.user_settings
set image_upload_consent = false, updated_at = '2026-08-10T00:02:00Z'
where user_id = '11111111-1111-4111-8111-111111111111';

select throws_ok(
  $$
    insert into storage.objects (bucket_id, name)
    values (
      'scan-images',
      '11111111-1111-4111-8111-111111111111/eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee/history.jpg'
    )
  $$,
  '42501',
  null,
  'Storage rejects new uploads after image consent is revoked'
);

select lives_ok(
  $$
    insert into public.scan_records (
      id,
      user_id,
      batch_id,
      fruit_type,
      ripeness_stage,
      model_confidence,
      result_origin,
      shelf_life_status,
      shelf_life_minimum,
      shelf_life_maximum,
      shelf_life_unit,
      shelf_life_guidance,
      shelf_life_evidence_version,
      model_version,
      created_at,
      updated_at
    ) values (
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      '11111111-1111-4111-8111-111111111111',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'carabao_mango',
      'ripe',
      0.9,
      'on_device_model',
      'available',
      1,
      3,
      'days',
      'Keep in a cool, dry place.',
      'provisional-v1',
      'model-v1',
      '2026-08-10T00:00:00Z',
      '2026-08-10T00:00:00Z'
    )
  $$,
  'an owner can add a compatible scan'
);

select lives_ok(
  $$
    insert into public.orders (
      id,
      user_id,
      batch_id,
      customer_name,
      delivery_address,
      delivery_date,
      status,
      created_at,
      updated_at
    ) values (
      'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
      '11111111-1111-4111-8111-111111111111',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'Synthetic customer',
      'Synthetic address',
      '2026-08-11T00:00:00Z',
      'completed',
      '2026-08-10T00:00:00Z',
      '2026-08-10T00:00:00Z'
    )
  $$,
  'an order can be created only for a nonempty batch'
);

select lives_ok(
  $$
    update public.scan_records
    set remote_image_key =
      '11111111-1111-4111-8111-111111111111/cccccccc-cccc-4ccc-8ccc-cccccccccccc/history.jpg'
    where id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
  $$,
  'completed-batch scans permit deterministic photo-key attachment'
);

select lives_ok(
  $$
    update public.scan_records
    set remote_image_key = null
    where id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
  $$,
  'completed-batch scans permit deterministic photo-key clearing'
);

select throws_ok(
  $$
    update public.scan_records
    set ripeness_stage = 'overripe', updated_at = '2026-08-10T00:03:00Z'
    where id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
  $$,
  'P0001',
  'completed_batch_locked',
  'completed batches still reject assessment edits'
);

select throws_ok(
  $$
    update public.scan_records
    set batch_id = null, updated_at = '2026-08-10T00:03:00Z'
    where id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
  $$,
  'P0001',
  'completed batches still reject scan movement'
);

select throws_ok(
  $$
    update public.batches
    set name = 'Forbidden completed edit', updated_at = '2026-08-10T00:03:00Z'
    where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  $$,
  'P0001',
  'completed_batch_locked',
  'completed orders lock their batch'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',
  true
);

select is(
  (select count(*)::integer from public.batches),
  0,
  'a second account cannot read the first account batch'
);
select is(
  (select count(*)::integer from public.scan_records),
  0,
  'a second account cannot read the first account scan'
);
select is(
  (select count(*)::integer from storage.objects where bucket_id = 'scan-images'),
  0,
  'a second account cannot list the first account image object'
);

set local role anon;
select throws_ok(
  $$ select count(*) from public.batches $$,
  '42501',
  null,
  'anonymous users cannot read domain rows'
);

select * from finish();
rollback;
