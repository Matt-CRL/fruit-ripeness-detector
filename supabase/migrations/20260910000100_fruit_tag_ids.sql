alter table public.scan_records
  add column if not exists fruit_tag_id text;

alter table public.scan_records
  drop constraint if exists scan_records_fruit_tag_id_check;

alter table public.scan_records
  add constraint scan_records_fruit_tag_id_check check (
    fruit_tag_id is null or fruit_tag_id ~ '^CH-[0-9]{6,}$'
  );

create or replace function public.enforce_scan_fruit_tag_id()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE'
    and old.fruit_tag_id is not null
    and new.fruit_tag_id is distinct from old.fruit_tag_id then
    raise exception 'scan_fruit_tag_id_immutable';
  end if;

  return new;
end;
$$;

drop trigger if exists scan_records_fruit_tag_id_before_write
  on public.scan_records;

create trigger scan_records_fruit_tag_id_before_write
before insert or update on public.scan_records
for each row execute function public.enforce_scan_fruit_tag_id();
