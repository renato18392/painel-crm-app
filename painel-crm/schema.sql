-- ============================================================
-- CRM + Financial Dashboard — PostgreSQL / Supabase schema
-- ============================================================
-- Run this in the Supabase SQL editor (or psql) on a fresh project.
-- Assumes Supabase Auth is used, so auth.users already exists and
-- user_id columns reference it directly (no separate "users" table
-- is needed — Supabase's auth.users covers profile auth fields;
-- add a "profiles" table only if you need extra public profile data).

create extension if not exists "uuid-ossp";

-- ---------- profiles (public-facing user data) ----------
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  email text,
  avatar text,
  company text,
  phone text,
  created_at timestamptz not null default now()
);

-- ---------- contacts ----------
create table if not exists contacts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  company text,
  whatsapp text,
  email text,
  instagram text,
  service text,
  potential_value numeric(12,2) default 0,
  status text not null default 'novo'
    check (status in ('novo','contatado','negociacao','proposta_enviada','fechado','perdido')),
  source text
    check (source in ('instagram','whatsapp','indicacao','workana','site','facebook','google','outro')),
  tags text[] default '{}',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_contact_at timestamptz,
  next_contact_at timestamptz
);
create index if not exists idx_contacts_user on contacts(user_id);
create index if not exists idx_contacts_status on contacts(status);

-- ---------- projects ----------
create table if not exists projects (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  contact_id uuid references contacts(id) on delete set null,
  name text not null,
  description text,
  value numeric(12,2) default 0,
  start_date date,
  deadline date,
  status text not null default 'planejamento'
    check (status in ('planejamento','em_andamento','aguardando_cliente','concluido','cancelado')),
  priority text default 'media'
    check (priority in ('baixa','media','alta','urgente')),
  progress int default 0 check (progress between 0 and 100),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_projects_user on projects(user_id);
create index if not exists idx_projects_contact on projects(contact_id);

-- ---------- earnings ----------
create table if not exists earnings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  contact_id uuid references contacts(id) on delete set null,
  project_id uuid references projects(id) on delete set null,
  value numeric(12,2) not null,
  date date not null default current_date,
  payment_method text check (payment_method in ('pix','dinheiro','cartao','transferencia','outro')),
  payment_status text not null default 'pendente'
    check (payment_status in ('recebido','pendente','atrasado','cancelado')),
  category text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_earnings_user on earnings(user_id);
create index if not exists idx_earnings_date on earnings(date);

-- ---------- activities ----------
create table if not exists activities (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  contact_id uuid references contacts(id) on delete cascade,
  project_id uuid references projects(id) on delete cascade,
  type text not null,
  description text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_activities_user on activities(user_id);

-- ---------- notifications ----------
create table if not exists notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  message text,
  type text,
  read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user on notifications(user_id);

-- ---------- follow_ups ----------
create table if not exists follow_ups (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  contact_id uuid references contacts(id) on delete cascade,
  date date not null,
  time time,
  description text,
  completed boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_followups_user on follow_ups(user_id);

-- ---------- settings ----------
create table if not exists settings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  currency text default 'BRL',
  theme text default 'auto' check (theme in ('light','dark','auto')),
  date_format text default 'DD/MM/YYYY',
  notifications_enabled boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- Row Level Security — every user only sees/edits their own rows
-- ============================================================
alter table profiles enable row level security;
alter table contacts enable row level security;
alter table projects enable row level security;
alter table earnings enable row level security;
alter table activities enable row level security;
alter table notifications enable row level security;
alter table follow_ups enable row level security;
alter table settings enable row level security;

create policy "own profile" on profiles for all using (auth.uid() = id);

create policy "own contacts" on contacts for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own projects" on projects for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own earnings" on earnings for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own activities" on activities for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own notifications" on notifications for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own followups" on follow_ups for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own settings" on settings for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Auto-update updated_at
create or replace function set_updated_at() returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

create trigger trg_contacts_updated before update on contacts
  for each row execute function set_updated_at();
create trigger trg_projects_updated before update on projects
  for each row execute function set_updated_at();
create trigger trg_earnings_updated before update on earnings
  for each row execute function set_updated_at();
create trigger trg_settings_updated before update on settings
  for each row execute function set_updated_at();
