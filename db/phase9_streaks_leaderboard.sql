-- CodePath Academy — Phase 9: daily streaks + leaderboard
-- New profiles columns (streak tracking) and a security-definer function
-- for a public leaderboard that doesn't expose the full profiles table
-- (email, account_type, etc.) to other students. Safe to run more than
-- once — every statement is idempotent.

alter table profiles add column if not exists current_streak integer not null default 0;
alter table profiles add column if not exists longest_streak integer not null default 0;
alter table profiles add column if not exists last_activity_date date;

-- Exposes only what a leaderboard needs — never email, account_type, or
-- anything else in profiles — so it's safe to let any signed-in student
-- call this, unlike loosening profiles' own SELECT policy would be.
create or replace function public.get_leaderboard(result_limit integer default 20)
returns table(id uuid, name text, xp integer, level integer)
as $$
  select id, name, xp, level
  from public.profiles
  order by xp desc, level desc
  limit result_limit;
$$ language sql security definer stable;

grant execute on function public.get_leaderboard(integer) to authenticated;
