begin;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 email text not null, name text not null,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 admin boolean not null default false
);
create table if not exists public.lists (
 id uuid primary key default gen_random_uuid(),
 owner uuid not null default auth.uid() references public.profiles(id) on delete cascade,
 name text not null check(length(trim(name)) between 1 and 120),
 ips text not null default '' check(octet_length(ips)<=1048576),
 public boolean not null default false,
 updated timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.lists enable row level security;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and admin and status='approved');
$$;
create or replace function public.is_approved() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and status='approved');
$$;
create or replace function public.ensure_profile() returns public.profiles language plpgsql security definer set search_path='' as $$
declare u auth.users; p public.profiles; elevated boolean;
begin
 select * into u from auth.users where id=auth.uid();
 if u.id is null or u.email_confirmed_at is null or not exists(select 1 from auth.identities where user_id=u.id and provider='google') then raise exception 'Inicie sessão com uma conta Google verificada.'; end if;
 elevated := lower(u.email)='joseeduardoalbuquerque@gmail.com';
 insert into public.profiles(id,email,name,status,admin) values(u.id,u.email,coalesce(u.raw_user_meta_data->>'full_name',u.email),case when elevated then 'approved' else 'pending' end,elevated)
 on conflict(id) do update set email=excluded.email,name=excluded.name;
 select * into p from public.profiles where id=u.id; return p;
end;
$$;
create or replace function public.set_user_status(target uuid,new_status text) returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_admin() then raise exception 'Apenas o administrador pode gerir acessos.'; end if;
 if new_status not in ('pending','approved','rejected') then raise exception 'Estado inválido.'; end if;
 update public.profiles set status=new_status where id=target and not admin;
 if not found then raise exception 'Utilizador não encontrado ou protegido.'; end if;
end;
$$;
create or replace function public.normalize_list() returns trigger language plpgsql set search_path='' as $$
declare entry text; normalized text := ''; seen text[] := '{}'; parsed inet;
begin
 if octet_length(new.ips)>1048576 then raise exception 'Máximo de 1 MB por lista.'; end if;
 foreach entry in array regexp_split_to_array(trim(new.ips),'[\s,;]+') loop
  if entry='' then continue; end if;
  if entry !~ '^[0-9a-fA-F:.]+(/[0-9]+)?$' then raise exception 'IP ou rede inválida: %',entry; end if;
  begin parsed := entry::inet; exception when others then raise exception 'IP ou rede inválida: %',entry; end;
  if family(parsed)=4 and split_part(entry,'/',1) !~ '^([0-9]{1,3}\.){3}[0-9]{1,3}$' then raise exception 'IPv4 deve ter quatro octetos: %',entry; end if;
  if not(entry=any(seen)) then seen:=array_append(seen,entry);normalized:=normalized || case when normalized='' then '' else E'\n' end || entry; end if;
 end loop;
 new.ips:=normalized;new.name:=trim(new.name);new.updated:=now();return new;
end;
$$;
drop trigger if exists normalize_list on public.lists;
create trigger normalize_list before insert or update on public.lists for each row execute function public.normalize_list();
drop policy if exists profile_read on public.profiles;
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid() or public.is_admin());
drop policy if exists list_owner on public.lists;
create policy list_owner on public.lists for all to authenticated using(owner=auth.uid() and public.is_approved()) with check(owner=auth.uid() and public.is_approved());
-- Apenas esta função expõe listas públicas; a tabela não tem leitura anónima.
create or replace function public.public_blacklist(list_id uuid) returns text language sql stable security definer set search_path='' as $$
 select case when l.ips='' then '' else l.ips || E'\n' end from public.lists l join public.profiles p on p.id=l.owner where l.id=list_id and l.public and p.status='approved';
$$;
revoke all on public.profiles,public.lists from anon,authenticated;
grant select on public.profiles to authenticated;
grant select,insert,delete on public.lists to authenticated;
grant update(name,ips,public) on public.lists to authenticated;
revoke all on function public.ensure_profile(),public.set_user_status(uuid,text),public.is_admin(),public.is_approved(),public.public_blacklist(uuid),public.normalize_list() from public;
grant execute on function public.ensure_profile(),public.set_user_status(uuid,text),public.is_admin(),public.is_approved() to authenticated;
grant execute on function public.public_blacklist(uuid) to anon;
commit;
