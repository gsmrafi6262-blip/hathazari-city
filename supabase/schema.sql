-- Hathazari City Guide: Supabase starter schema
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text unique,
  role text not null default 'user' check (role in ('user','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name_bn text not null,
  name_en text not null,
  icon text default '📍',
  sort_order int not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id uuid references public.categories(id) on delete set null,
  description text,
  phone text,
  address text not null,
  latitude double precision,
  longitude double precision,
  image_url text,
  submitted_by uuid references auth.users(id) on delete set null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.doctors (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references public.businesses(id) on delete cascade,
  name text not null,
  specialty text,
  qualification text,
  chamber_time text,
  phone text,
  created_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  rating int not null check (rating between 1 and 5),
  comment text,
  status text not null default 'pending' check (status in ('pending','approved','hidden')),
  created_at timestamptz not null default now()
);

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid not null references public.businesses(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id,business_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.advertisements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_url text,
  target_url text,
  starts_at timestamptz,
  ends_at timestamptz,
  active boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists businesses_category_idx on public.businesses(category_id);
create index if not exists businesses_status_idx on public.businesses(status);
create index if not exists reviews_business_idx on public.reviews(business_id);

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.businesses enable row level security;
alter table public.doctors enable row level security;
alter table public.reviews enable row level security;
alter table public.favorites enable row level security;
alter table public.notifications enable row level security;
alter table public.advertisements enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public
as $$ select exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'); $$;

create policy "profiles read own" on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "profiles update own" on public.profiles for update to authenticated using (id = auth.uid() or public.is_admin());
create policy "categories public read" on public.categories for select using (active or public.is_admin());
create policy "categories admin manage" on public.categories for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "approved businesses public read" on public.businesses for select using (status = 'approved' or submitted_by = auth.uid() or public.is_admin());
create policy "users submit business" on public.businesses for insert to authenticated with check (submitted_by = auth.uid() and status = 'pending');
create policy "admin manage businesses" on public.businesses for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "doctors public read via approved business" on public.doctors for select using (exists(select 1 from public.businesses b where b.id = business_id and b.status = 'approved') or public.is_admin());
create policy "admin manage doctors" on public.doctors for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "reviews public approved" on public.reviews for select using (status = 'approved' or user_id = auth.uid() or public.is_admin());
create policy "users create review" on public.reviews for insert to authenticated with check (user_id = auth.uid() and status = 'pending');
create policy "admin manage reviews" on public.reviews for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "favorites own" on public.favorites for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "notifications own" on public.notifications for select to authenticated using (user_id is null or user_id = auth.uid() or public.is_admin());
create policy "notifications admin manage" on public.notifications for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "active ads public read" on public.advertisements for select using (active or public.is_admin());
create policy "admin manage ads" on public.advertisements for all to authenticated using (public.is_admin()) with check (public.is_admin());

insert into public.categories(name_bn,name_en,icon,sort_order) values
('হাসপাতাল ও ডায়াগনস্টিক','Hospital & Diagnostic','🏥',1),
('ডাক্তার','Doctors','🩺',2),('হোটেল ও রেস্টুরেন্ট','Hotels & Restaurants','🍽️',3),
('শপিং ও বাজার','Shopping & Markets','🛍️',4),('স্কুল ও কলেজ','Schools & Colleges','🎓',5),
('মসজিদ ও ধর্মীয় স্থান','Mosques & Religious Places','🕌',6),('পরিবহন ও গাড়ি ভাড়া','Transport & Rent a Car','🚕',7),
('জরুরি সেবা','Emergency Services','🚨',8),('দর্শনীয় স্থান','Tourist Places','🏞️',9),
('ব্যবসা প্রতিষ্ঠান','Businesses','🏢',10),('ফার্মেসি','Pharmacy','💊',11),
('ব্যাংক ও আর্থিক সেবা','Banks & Finance','🏦',12),('খেলাধুলা','Sports','⚽',13)
on conflict do nothing;
