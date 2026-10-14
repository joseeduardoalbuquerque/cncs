insert into auth.users values
 ('00000000-0000-0000-0000-000000000001','joseeduardoalbuquerque@gmail.com',now(),'{"full_name":"Admin"}'),
 ('00000000-0000-0000-0000-000000000002','owner@example.com',now(),'{}'),
 ('00000000-0000-0000-0000-000000000003','other@example.com',now(),'{}');
insert into auth.identities select id,'google' from auth.users;
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.ensure_profile();
do $$begin if not public.is_admin() then raise exception 'Admin bootstrap failed';end if;end$$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',false);
select public.ensure_profile();
do $$begin
 begin insert into public.lists(name) values('blocked');raise exception 'Pending user inserted list';exception when insufficient_privilege then null;end;
 begin perform public.set_user_status(auth.uid(),'approved');raise exception 'Self approval succeeded';exception when raise_exception then if sqlerrm='Self approval succeeded' then raise;end if;end;
 begin update public.profiles set admin=true where id=auth.uid();raise exception 'Privilege escalation';exception when insufficient_privilege then null;end;
end$$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.set_user_status('00000000-0000-0000-0000-000000000002','approved');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',false);
insert into public.lists(id,name,ips) values('10000000-0000-0000-0000-000000000001','Test',E'192.0.2.1\n192.0.2.1\n2001:db8::/32');
do $$begin
 if (select ips from public.lists limit 1)<>E'192.0.2.1\n2001:db8::/32' then raise exception 'Normalization failed';end if;
 begin update public.lists set ips='192.0.2.1/33';raise exception 'Invalid IP accepted';exception when raise_exception then if sqlerrm='Invalid IP accepted' then raise;end if;end;
end$$;
set role anon;
do $$begin if public.public_blacklist('10000000-0000-0000-0000-000000000001') is not null then raise exception 'Private list exposed';end if;end$$;
set role authenticated;
update public.lists set public=true;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',false);
select public.ensure_profile();
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.set_user_status('00000000-0000-0000-0000-000000000003','approved');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',false);
do $$declare n int;begin
 if exists(select 1 from public.lists) then raise exception 'Other owner can read';end if;
 update public.lists set name='hacked';get diagnostics n=row_count;if n<>0 then raise exception 'Other owner can edit';end if;
 delete from public.lists;get diagnostics n=row_count;if n<>0 then raise exception 'Other owner can delete';end if;
end$$;
set role anon;
do $$begin if public.public_blacklist('10000000-0000-0000-0000-000000000001')<>E'192.0.2.1\n2001:db8::/32\n' then raise exception 'Public TXT failed';end if;end$$;
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false);
select public.set_user_status('00000000-0000-0000-0000-000000000002','rejected');
set role anon;
do $$begin if public.public_blacklist('10000000-0000-0000-0000-000000000001') is not null then raise exception 'Revoked account exposed';end if;end$$;
set role authenticated;
select public.set_user_status('00000000-0000-0000-0000-000000000002','approved');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',false);
update public.lists set public=false;
set role anon;
do $$begin if public.public_blacklist('10000000-0000-0000-0000-000000000001') is not null then raise exception 'Unsharing failed';end if;end$$;
set role authenticated;
delete from public.lists;
set role anon;
do $$begin if public.public_blacklist('10000000-0000-0000-0000-000000000001') is not null then raise exception 'Deletion failed';end if;end$$;
reset role;
