"use server";

import Stripe from "stripe";
import { redirect as plainRedirect } from "next/navigation";
import { headers } from "next/headers";
import { redirect } from "@/i18n/navigation";
import { getLocale } from "next-intl/server";
import { createClient } from "@/lib/supabase/server";
import { createServiceClient } from "@/lib/supabase/service";

function getStripe(): Stripe | null {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) return null;
  return new Stripe(key);
}

async function currentOrigin() {
  const headerList = await headers();
  const host = headerList.get("host") ?? "";
  const protocol =
    headerList.get("x-forwarded-proto") ?? (host.startsWith("localhost") ? "http" : "https");
  return headerList.get("origin") ?? `${protocol}://${host}`;
}

/**
 * Starts a Stripe Checkout session for CodePath Pro and redirects the
 * student straight to Stripe's hosted checkout page. Falls back to the
 * pricing section (silently, no error banner — this state only happens
 * before the site owner has configured Stripe, never for a real visitor
 * once it's set up) if payments aren't configured or something goes wrong.
 */
export async function startCheckout() {
  const locale = await getLocale();
  const stripe = getStripe();
  const priceId = process.env.STRIPE_PRICE_ID;

  if (!stripe || !priceId || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    redirect({ href: "/#pricing", locale });
    return;
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    redirect({ href: "/login", locale });
    return;
  }

  // subscriptions has no write policy for regular users (only admins can
  // write directly; everyone else only has SELECT on their own row) — the
  // customer-id cache write below has to go through the service-role
  // client. Safe here specifically because customerId comes from Stripe's
  // own API response, not from anything client-supplied.
  const service = createServiceClient();
  const { data: subscription } = await service
    .from("subscriptions")
    .select("*")
    .eq("user_id", user.id)
    .maybeSingle();

  let customerId = subscription?.stripe_customer_id ?? null;
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: user.email,
      metadata: { supabase_user_id: user.id },
    });
    customerId = customer.id;
    await service.from("subscriptions").update({ stripe_customer_id: customerId }).eq("user_id", user.id);
  }

  const origin = await currentOrigin();

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${origin}/dashboard?upgraded=1`,
    cancel_url: `${origin}/#pricing`,
    metadata: { supabase_user_id: user.id },
  });

  if (!session.url) {
    redirect({ href: "/#pricing", locale });
    return;
  }

  plainRedirect(session.url);
}

/**
 * Sends an existing Pro student to Stripe's hosted Customer Portal, where
 * they can update their payment method or cancel — CodePath Academy never
 * needs to build its own billing-management UI for this.
 */
export async function manageBilling() {
  const locale = await getLocale();
  const stripe = getStripe();
  if (!stripe) {
    redirect({ href: "/dashboard", locale });
    return;
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    redirect({ href: "/login", locale });
    return;
  }

  const { data: subscription } = await supabase
    .from("subscriptions")
    .select("stripe_customer_id")
    .eq("user_id", user.id)
    .maybeSingle();

  if (!subscription?.stripe_customer_id) {
    redirect({ href: "/dashboard", locale });
    return;
  }

  const origin = await currentOrigin();

  const session = await stripe.billingPortal.sessions.create({
    customer: subscription.stripe_customer_id,
    return_url: `${origin}/dashboard`,
  });

  plainRedirect(session.url);
}
