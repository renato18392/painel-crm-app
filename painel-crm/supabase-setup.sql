-- ============================================================
-- Painel CRM — banco de dados para contas na nuvem (Supabase)
-- Rode este arquivo UMA vez em: Supabase → SQL Editor → New query → Run
-- ============================================================
-- Cada conta guarda seus dados em linhas próprias (uma por coleção:
-- contacts, projects, earnings, expenses, settings, activities).
-- O RLS garante que cada usuário só enxerga e altera as PRÓPRIAS linhas.

create table if not exists public.crm_data (
  user_id    uuid        not null references auth.users(id) on delete cascade,
  key        text        not null,
  value      jsonb       not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);

alter table public.crm_data enable row level security;

create policy "ver proprios dados"     on public.crm_data for select using (auth.uid() = user_id);
create policy "criar proprios dados"   on public.crm_data for insert with check (auth.uid() = user_id);
create policy "editar proprios dados"  on public.crm_data for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "apagar proprios dados"  on public.crm_data for delete using (auth.uid() = user_id);

create or replace function public.crm_touch() returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

create trigger crm_data_touch before update on public.crm_data
  for each row execute function public.crm_touch();
