create extension if not exists pgcrypto with schema extensions;

create table public.offline_workspace_links (
  user_id uuid primary key references auth.users(id) on delete cascade,
  workspace_id uuid not null unique,
  installation_id uuid not null,
  revocation_token_hash text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index offline_workspace_links_installation_idx
  on public.offline_workspace_links (installation_id);

create or replace function public.touch_offline_workspace_link()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = clock_timestamp();
  return new;
end;
$$;

create trigger offline_workspace_links_touch
before update on public.offline_workspace_links
for each row execute function public.touch_offline_workspace_link();

alter table public.offline_workspace_links enable row level security;
revoke all on public.offline_workspace_links from anon, authenticated;

create or replace function public.offline_workspace_link_status(p_workspace_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return 'unavailable';
  end if;

  if exists (
    select 1 from public.offline_workspace_links
    where user_id = auth.uid() and workspace_id = p_workspace_id
  ) then
    return 'local_already_linked';
  end if;

  if exists (
    select 1 from public.offline_workspace_links
    where user_id = auth.uid()
  ) then
    return 'linked_elsewhere';
  end if;

  if exists (
    select 1 from public.offline_workspace_links
    where workspace_id = p_workspace_id
  ) then
    return 'workspace_linked';
  end if;

  return 'eligible';
end;
$$;

create or replace function public.claim_offline_workspace_link(
  p_workspace_id uuid,
  p_installation_id uuid,
  p_revocation_token text
)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if auth.uid() is null or p_revocation_token is null
     or length(trim(p_revocation_token)) < 16 then
    return 'unavailable';
  end if;

  if exists (
    select 1 from public.offline_workspace_links
    where user_id = auth.uid() and workspace_id = p_workspace_id
  ) then
    return 'local_already_linked';
  end if;

  if exists (
    select 1 from public.offline_workspace_links
    where user_id = auth.uid()
  ) then
    return 'linked_elsewhere';
  end if;

  if exists (
    select 1 from public.offline_workspace_links
    where workspace_id = p_workspace_id
  ) then
    return 'workspace_linked';
  end if;

  insert into public.offline_workspace_links (
    user_id, workspace_id, installation_id, revocation_token_hash
  ) values (
    auth.uid(), p_workspace_id, p_installation_id,
    encode(extensions.digest(p_revocation_token, 'sha256'), 'hex')
  );
  return 'linked';
exception
  when unique_violation then
    return 'workspace_linked';
end;
$$;

create or replace function public.release_offline_workspace_link(
  p_workspace_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then return false; end if;
  delete from public.offline_workspace_links
  where user_id = auth.uid() and workspace_id = p_workspace_id;
  return found;
end;
$$;

create or replace function public.release_offline_workspace_link_with_token(
  p_workspace_id uuid,
  p_revocation_token text
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if p_revocation_token is null then return false; end if;
  delete from public.offline_workspace_links
  where workspace_id = p_workspace_id
    and revocation_token_hash =
      encode(extensions.digest(p_revocation_token, 'sha256'), 'hex');
  return found;
end;
$$;

revoke all on function public.touch_offline_workspace_link() from public, anon, authenticated;
revoke all on function public.offline_workspace_link_status(uuid) from public, anon;
revoke all on function public.claim_offline_workspace_link(uuid, uuid, text) from public, anon;
revoke all on function public.release_offline_workspace_link(uuid) from public, anon;
revoke all on function public.release_offline_workspace_link_with_token(uuid, text) from public;
grant execute on function public.offline_workspace_link_status(uuid) to authenticated;
grant execute on function public.claim_offline_workspace_link(uuid, uuid, text) to authenticated;
grant execute on function public.release_offline_workspace_link(uuid) to authenticated;
grant execute on function public.release_offline_workspace_link_with_token(uuid, text) to anon, authenticated;
