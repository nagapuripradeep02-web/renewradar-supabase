-- core schema for RenewRadar (staging)
-- Safe to run multiple times on empty DB.

create extension if not exists pgcrypto;

-- ---------- Types
do $$ begin
  if not exists (select 1 from pg_type where typname = 'contract_status') then
    create type contract_status as enum ('active','cancellation_scheduled','cancelled','ended');
  end if;
  if not exists (select 1 from pg_type where typname = 'trial_status') then
    create type trial_status as enum ('active','cancelled','expired');
  end if;
end $$;

-- ---------- Tables
create table if not exists public.providers (
  id              uuid primary key default gen_random_uuid(),
  name            text not null unique,
  kind            text check (kind in ('mobile','wifi','energy','gym','video','music','software','other')) default 'other',
  email_domain    text,
  cancellation_url text,
  requires_letter boolean default false,
  country_code    text default 'DE',
  metadata        jsonb not null default '{}',
  created_at      timestamptz not null default now()
);

create table if not exists public.contracts (
  id                 uuid primary key default gen_random_uuid(),
  owner              uuid not null default auth.uid(),        -- who owns this row
  provider_id        uuid references public.providers(id),
  product_name       text,
  contract_number    text,
  start_date         date,
  min_term_months    int  default 0,
  notice_period_days int  default 0,
  status             contract_status not null default 'active',
  notes              text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  -- computed helper dates
  earliest_end_date  date generated always as (
    (start_date + make_interval(months => coalesce(min_term_months,0)))
  ) stored,
  cancel_by_date     date generated always as (
    (start_date + make_interval(months => coalesce(min_term_months,0)) - make_interval(days => coalesce(notice_period_days,0)))
  ) stored
);

create table if not exists public.trials (
  id               uuid primary key default gen_random_uuid(),
  owner            uuid not null default auth.uid(),
  provider_id      uuid references public.providers(id),
  product_name     text,
  platform         text check (platform in ('android','ios','web','play','xbox','other')) default 'web',
  start_date       date not null,
  trial_length_days int  not null default 7,
  status           trial_status not null default 'active',
  notes            text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  cancel_by_date   date generated always as (
    (start_date + make_interval(days => coalesce(trial_length_days,0) - 1))
  ) stored
);

create table if not exists public.reminders (
  id          uuid primary key default gen_random_uuid(),
  owner       uuid not null default auth.uid(),
  kind        text check (kind in ('trial','contract','bill','custom')) not null,
  ref_id      uuid,                       -- points to trials.id or contracts.id when relevant
  subject     text not null,
  due_at      timestamptz not null,
  channels    text[] not null default array['push'],
  sent_at     timestamptz,
  created_at  timestamptz not null default now()
);

create table if not exists public.documents (
  id          uuid primary key default gen_random_uuid(),
  owner       uuid not null default auth.uid(),
  contract_id uuid references public.contracts(id),
  trial_id    uuid references public.trials(id),
  file_path   text not null,              -- storage path (bucket/key)
  mime_type   text,
  page_count  int,
  created_at  timestamptz not null default now()
);

-- ---------- Row owners indexes
create index if not exists idx_contracts_owner on public.contracts(owner);
create index if not exists idx_trials_owner    on public.trials(owner);
create index if not exists idx_reminders_owner on public.reminders(owner);
create index if not exists idx_docs_owner      on public.documents(owner);

-- ---------- RLS
alter table public.providers enable row level security;
alter table public.contracts enable row level security;
alter table public.trials    enable row level security;
alter table public.reminders enable row level security;
alter table public.documents enable row level security;

-- Providers: readable by everyone (no secrets), no writes from client
drop policy if exists "providers read for all" on public.providers;
create policy "providers read for all"
  on public.providers for select
  using (true);

-- Owner-only CRUD for user-scoped tables
create policy if not exists "contracts owner read"
  on public.contracts for select using (owner = auth.uid());
create policy if not exists "contracts owner write"
  on public.contracts for all    using (owner = auth.uid()) with check (owner = auth.uid());

create policy if not exists "trials owner read"
  on public.trials for select using (owner = auth.uid());
create policy if not exists "trials owner write"
  on public.trials for all    using (owner = auth.uid()) with check (owner = auth.uid());

create policy if not exists "reminders owner read"
  on public.reminders for select using (owner = auth.uid());
create policy if not exists "reminders owner write"
  on public.reminders for all    using (owner = auth.uid()) with check (owner = auth.uid());

create policy if not exists "documents owner read"
  on public.documents for select using (owner = auth.uid());
create policy if not exists "documents owner write"
  on public.documents for all    using (owner = auth.uid()) with check (owner = auth.uid());

-- ---------- Triggers for updated_at
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$ begin
  if not exists (select 1 from pg_trigger where tgname = 'trg_contracts_touch') then
    create trigger trg_contracts_touch before update on public.contracts
      for each row execute function public.touch_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'trg_trials_touch') then
    create trigger trg_trials_touch before update on public.trials
      for each row execute function public.touch_updated_at();
  end if;
end $$;

-- ---------- Seed common providers (you can extend later)
insert into public.providers (name,kind,email_domain,cancellation_url,requires_letter,country_code)
values
  ('Vodafone', 'mobile', 'vodafone.de', 'https://www.vodafone.de/hilfe/kuendigung.html', false, 'DE'),
  ('Telekom',  'mobile', 'telekom.de',  'https://www.telekom.de/hilfe/kuendigen',       false, 'DE'),
  ('o2',       'mobile', 'o2online.de', 'https://www.o2online.de/kuendigen/',           false, 'DE'),
  ('FitX',     'gym',    null,          null,                                           true,  'DE'),
  ('McFIT',    'gym',    null,          null,                                           true,  'DE'),
  ('Netflix',  'video',  'netflix.com', 'https://www.netflix.com/cancel',               false, 'DE'),
  ('Spotify',  'music',  'spotify.com', 'https://www.spotify.com/account/subscription/cancel', false, 'DE'),
  ('LinkedIn', 'software','linkedin.com','https://www.linkedin.com/psettings/autorenew', false, 'DE'),
  ('OpenAI',   'software','openai.com', 'https://platform.openai.com/account/billing',  false, 'DE')
on conflict (name) do nothing;

-- ---------- Unified view: upcoming deadlines (trials + contracts)
create or replace view public.v_upcoming_deadlines as
select
  'trial'::text as kind,
  t.id,
  t.owner,
  coalesce(p.name, 'Unknown') as provider,
  t.product_name,
  t.cancel_by_date as due_date,
  t.status::text as status,
  t.created_at
from public.trials t
left join public.providers p on p.id = t.provider_id
union all
select
  'contract'::text as kind,
  c.id,
  c.owner,
  coalesce(p.name, 'Unknown') as provider,
  c.product_name,
  c.cancel_by_date as due_date,
  c.status::text as status,
  c.created_at
from public.contracts c
left join public.providers p on p.id = c.provider_id;

alter view public.v_upcoming_deadlines owner to authenticated;
