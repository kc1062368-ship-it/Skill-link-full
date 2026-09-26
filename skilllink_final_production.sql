-- SkillLink FINAL PRODUCTION SCHEMA
-- Run in Supabase SQL Editor. Safe to run in parts if needed.
create extension if not exists pgcrypto;

create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,full_name text,username text unique,role text not null default 'partner' check(role in ('ceo','admin','partner','client')),referral_code text unique,referred_by uuid references public.profiles(id) on delete set null,phone text,avatar_url text,active boolean not null default true,created_at timestamptz not null default now());

create or replace function public.make_referral_code() returns text language plpgsql security definer set search_path=public as $$declare c text;begin loop c:='SL'||upper(substr(md5(random()::text||clock_timestamp()::text),1,8)); exit when not exists(select 1 from public.profiles where referral_code=c); end loop; return c; end$$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$begin insert into public.profiles(id,full_name,username,referral_code) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),nullif(new.raw_user_meta_data->>'username',''),public.make_referral_code()) on conflict(id) do nothing; return new; end$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create table if not exists public.packages(id uuid primary key default gen_random_uuid(),name text unique not null,subtitle text,price numeric(10,2) not null default 0,partner_commission numeric(10,2) not null default 0,active boolean not null default true,created_at timestamptz not null default now());
create table if not exists public.courses(id uuid primary key default gen_random_uuid(),package_id uuid references public.packages(id) on delete cascade,title text not null,description text,category text,sort_order integer not null default 0,active boolean not null default true,created_at timestamptz not null default now());
create table if not exists public.course_videos(id uuid primary key default gen_random_uuid(),course_id uuid not null references public.courses(id) on delete cascade,title text not null,video_url text not null,description text,sort_order integer not null default 0,active boolean not null default true,created_at timestamptz not null default now());
create table if not exists public.course_tests(id uuid primary key default gen_random_uuid(),course_id uuid unique not null references public.courses(id) on delete cascade,title text not null default 'Course Test',passing_percent integer not null default 60 check(passing_percent between 1 and 100),active boolean not null default true,created_at timestamptz not null default now());
create table if not exists public.test_questions(id uuid primary key default gen_random_uuid(),test_id uuid not null references public.course_tests(id) on delete cascade,question text not null,option_a text not null,option_b text not null,option_c text,option_d text,correct_option text not null check(correct_option in('A','B','C','D')),sort_order integer not null default 0);
create table if not exists public.test_attempts(id uuid primary key default gen_random_uuid(),test_id uuid not null references public.course_tests(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,score_percent integer not null default 0,passed boolean not null default false,attempted_at timestamptz not null default now());
create table if not exists public.certificates(id uuid primary key default gen_random_uuid(),course_id uuid not null references public.courses(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,certificate_no text unique not null,issued_at timestamptz not null default now(),verification_code text unique not null);
create table if not exists public.enrollments(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,course_id uuid not null references public.courses(id) on delete cascade,status text not null default 'active' check(status in('active','completed','paused')),progress integer not null default 0 check(progress between 0 and 100),enrolled_at timestamptz not null default now(),completed_at timestamptz,unique(user_id,course_id));

create table if not exists public.projects(id uuid primary key default gen_random_uuid(),title text not null,description text,category text,reward numeric(10,2) not null default 0,status text not null default 'open' check(status in('open','assigned','submitted','approved','closed')),client_id uuid references public.profiles(id) on delete set null,assigned_to uuid references public.profiles(id) on delete set null,created_by uuid references public.profiles(id) on delete set null,created_at timestamptz not null default now());
create table if not exists public.project_submissions(id uuid primary key default gen_random_uuid(),project_id uuid not null references public.projects(id) on delete cascade,partner_id uuid not null references public.profiles(id) on delete cascade,submission_url text,notes text,status text not null default 'submitted' check(status in('submitted','approved','rejected')),submitted_at timestamptz not null default now(),reviewed_at timestamptz);
create table if not exists public.referrals(id uuid primary key default gen_random_uuid(),referrer_id uuid not null references public.profiles(id) on delete cascade,referred_user_id uuid not null references public.profiles(id) on delete cascade,status text not null default 'registered' check(status in('registered','valid','inactive')),created_at timestamptz not null default now(),unique(referrer_id,referred_user_id));
create table if not exists public.earnings_ledger(id uuid primary key default gen_random_uuid(),partner_id uuid not null references public.profiles(id) on delete cascade,project_id uuid references public.projects(id) on delete set null,description text not null,gross_amount numeric(10,2) not null default 0,company_share numeric(10,2) not null default 0,partner_share numeric(10,2) not null default 0,status text not null default 'pending' check(status in('pending','available','withdrawn','reversed')),created_at timestamptz not null default now());
create table if not exists public.withdrawals(id uuid primary key default gen_random_uuid(),partner_id uuid not null references public.profiles(id) on delete cascade,amount numeric(10,2) not null check(amount>=100),upi_id text,status text not null default 'pending' check(status in('pending','approved','rejected','paid')),approved_by uuid references public.profiles(id) on delete set null,note text,created_at timestamptz not null default now(),processed_at timestamptz);
create table if not exists public.user_progress(user_id uuid primary key references public.profiles(id) on delete cascade,points integer not null default 0,current_level integer not null default 1,skill_masteries integer not null default 0,updated_at timestamptz not null default now());

create table if not exists public.levels(id integer primary key,name text unique not null,points integer not null,referrals integer not null default 0,masteries integer not null default 0,reward text not null);
delete from public.levels;
insert into public.levels values
(1,'Starter Partner',100,0,0,'Official SkillLink ID Card + SkillLink Branded T-Shirt'),
(2,'Rising Partner',250,15,1,'Premium SkillLink Backpack, Wireless Earbuds, Premium Notebook, Branded Pen Set, Achievement Certificate, ID Card Holder'),
(3,'Skilled Partner',400,20,1,'Premium Smartwatch, 20,000mAh Power Bank, Mobile Stand, Achievement Certificate'),
(4,'Advanced Partner',500,25,2,'Study Table, Bluetooth Speaker, Simple Premium Watch'),
(5,'Pro Partner',650,30,2,'Premium Travel Backpack, Wireless Microphone, Professional Desk Accessories'),
(6,'Expert Partner',800,40,3,'Premium Productivity Gadget Kit including high-quality headphones and professional tech accessories'),
(7,'Elite Partner',1000,50,4,'Goa — 3 Days / 2 Nights premium travel experience'),
(8,'Master Partner',1500,60,5,'Udaipur — 4 Days / 3 Nights premium travel experience'),
(9,'Legend Partner',2000,75,6,'Jaipur + Pushkar — 5 Days / 4 Nights luxury travel experience');

create table if not exists public.masterclasses(id uuid primary key default gen_random_uuid(),title text not null,description text,link text not null,class_date date not null,class_time time,status text not null default 'published' check(status in('draft','published','archived')),created_by uuid references public.profiles(id) on delete set null,created_at timestamptz not null default now());
create table if not exists public.notifications(id uuid primary key default gen_random_uuid(),user_id uuid references public.profiles(id) on delete cascade,title text not null,message text not null,created_at timestamptz not null default now(),read_at timestamptz);

insert into public.packages(name,subtitle,price,partner_commission) values
('Aarambh','Digital Foundation',499,100),('Udaan','Creative + Content Skills',999,200),('Pragati','Marketing + Client Skills',1999,400),('Brahmastra','Advanced Digital Skills',3999,800),('Shikhar','Leadership + Business',6999,1400)
on conflict(name) do update set subtitle=excluded.subtitle,price=excluded.price,partner_commission=excluded.partner_commission;

-- RLS
alter table public.profiles enable row level security; alter table public.packages enable row level security; alter table public.courses enable row level security; alter table public.course_videos enable row level security; alter table public.course_tests enable row level security; alter table public.test_questions enable row level security; alter table public.test_attempts enable row level security; alter table public.certificates enable row level security; alter table public.enrollments enable row level security; alter table public.projects enable row level security; alter table public.project_submissions enable row level security; alter table public.referrals enable row level security; alter table public.earnings_ledger enable row level security; alter table public.withdrawals enable row level security; alter table public.user_progress enable row level security; alter table public.levels enable row level security; alter table public.masterclasses enable row level security; alter table public.notifications enable row level security;

create or replace function public.current_role() returns text language sql stable security definer set search_path=public as $$select role from public.profiles where id=auth.uid()$$;
create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.profiles where id=auth.uid() and role in('ceo','admin'))$$;
create or replace function public.is_ceo() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from public.profiles where id=auth.uid() and role='ceo')$$;

-- Drop policies so this file can be re-run.
do $$declare r record;begin for r in select schemaname,tablename,policyname from pg_policies where schemaname='public' loop execute format('drop policy if exists %I on %I.%I',r.policyname,r.schemaname,r.tablename); end loop;end$$;
create policy profiles_self on public.profiles for select using(id=auth.uid() or public.is_staff());
create policy profiles_update_self on public.profiles for update using(id=auth.uid() or public.is_ceo()) with check(id=auth.uid() or public.is_ceo());
create policy packages_public_read on public.packages for select using(active=true or public.is_staff());
create policy packages_ceo_write on public.packages for all using(public.is_ceo()) with check(public.is_ceo());
create policy courses_public_read on public.courses for select using(active=true or public.is_staff());
create policy courses_ceo_write on public.courses for all using(public.is_ceo()) with check(public.is_ceo());
create policy videos_read on public.course_videos for select using(active=true or public.is_staff());
create policy videos_ceo_write on public.course_videos for all using(public.is_ceo()) with check(public.is_ceo());
create policy tests_read on public.course_tests for select using(active=true or public.is_staff());
create policy tests_ceo_write on public.course_tests for all using(public.is_ceo()) with check(public.is_ceo());
create policy questions_read on public.test_questions for select using(true);
create policy questions_ceo_write on public.test_questions for all using(public.is_ceo()) with check(public.is_ceo());
create policy attempts_self on public.test_attempts for all using(user_id=auth.uid() or public.is_staff()) with check(user_id=auth.uid() or public.is_staff());
create policy cert_self on public.certificates for select using(user_id=auth.uid() or public.is_staff());
create policy cert_ceo_write on public.certificates for all using(public.is_ceo()) with check(public.is_ceo());
create policy enroll_self on public.enrollments for all using(user_id=auth.uid() or public.is_staff()) with check(user_id=auth.uid() or public.is_staff());
create policy projects_read on public.projects for select using(true);
create policy projects_staff_write on public.projects for all using(public.is_staff()) with check(public.is_staff());
create policy projects_partner_claim on public.projects for update using(public.current_role()='partner' and status='open') with check(assigned_to=auth.uid());
create policy submissions_owner on public.project_submissions for all using(partner_id=auth.uid() or public.is_staff()) with check(partner_id=auth.uid() or public.is_staff());
create policy referrals_self on public.referrals for select using(referrer_id=auth.uid() or referred_user_id=auth.uid() or public.is_staff());
create policy referrals_staff_write on public.referrals for all using(public.is_staff()) with check(public.is_staff());
create policy earnings_self on public.earnings_ledger for select using(partner_id=auth.uid() or public.is_staff());
create policy earnings_staff_write on public.earnings_ledger for all using(public.is_staff()) with check(public.is_staff());
create policy withdrawals_self on public.withdrawals for select using(partner_id=auth.uid() or public.is_staff());
create policy withdrawals_own_insert on public.withdrawals for insert with check(partner_id=auth.uid() and public.current_role() in('partner','admin') and amount>=100);
create policy withdrawals_ceo_update on public.withdrawals for update using(public.is_ceo()) with check(public.is_ceo());
create policy progress_self on public.user_progress for all using(user_id=auth.uid() or public.is_staff()) with check(user_id=auth.uid() or public.is_staff());
create policy levels_read on public.levels for select using(true);
create policy levels_ceo_write on public.levels for all using(public.is_ceo()) with check(public.is_ceo());
create policy masterclass_read on public.masterclasses for select using(status='published' or public.is_ceo());
create policy masterclass_ceo_write on public.masterclasses for all using(public.is_ceo()) with check(public.is_ceo());
create policy notifications_self on public.notifications for select using(user_id=auth.uid());
create policy notifications_staff_write on public.notifications for all using(public.is_staff()) with check(public.is_staff());

grant usage on schema public to anon,authenticated;
grant select on public.packages,public.courses,public.course_videos,public.course_tests,public.test_questions,public.levels,public.masterclasses,public.projects to anon,authenticated;
grant select,insert,update,delete on public.profiles,public.enrollments,public.project_submissions,public.referrals,public.earnings_ledger,public.withdrawals,public.user_progress,public.test_attempts,public.certificates,public.notifications to authenticated;
grant insert,update,delete on public.packages,public.courses,public.course_videos,public.course_tests,public.test_questions,public.levels,public.masterclasses,public.projects to authenticated;

-- IMPORTANT: After creating the CEO auth account, assign its role with:
-- update public.profiles set role='ceo' where id=(select id from auth.users where email='CEO_EMAIL');
