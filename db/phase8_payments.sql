-- CodePath Academy — Phase 8: real Stripe payments
-- Adds two nullable columns to the existing subscriptions table so it can
-- be linked to a real Stripe customer/subscription. Safe to run more than
-- once ("add column if not exists"), safe on a database that's never seen
-- this file before.

alter table subscriptions add column if not exists stripe_customer_id text;
alter table subscriptions add column if not exists stripe_subscription_id text;

-- Every webhook lookup goes stripe_subscription_id -> user, so this needs
-- to be fast and (once set) unique per subscription.
create unique index if not exists subscriptions_stripe_subscription_id_key
  on subscriptions (stripe_subscription_id)
  where stripe_subscription_id is not null;
