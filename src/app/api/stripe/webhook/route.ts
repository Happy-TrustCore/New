import Stripe from "stripe";
import { NextResponse, type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/service";

// Not under src/app/[locale] on purpose — webhooks are locale-less,
// cookie-less server-to-server requests, and src/proxy.ts explicitly
// excludes /api from the locale/auth middleware so this route receives
// Stripe's raw POST untouched.

function statusFromStripe(status: Stripe.Subscription.Status): "active" | "canceled" | "expired" {
  if (status === "active" || status === "trialing") return "active";
  if (status === "canceled" || status === "unpaid") return "canceled";
  return "expired";
}

export async function POST(request: NextRequest) {
  const secretKey = process.env.STRIPE_SECRET_KEY;
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!secretKey || !webhookSecret || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    return NextResponse.json({ error: "Stripe isn't configured." }, { status: 503 });
  }

  const signature = request.headers.get("stripe-signature");
  if (!signature) {
    return NextResponse.json({ error: "Missing signature." }, { status: 400 });
  }

  const stripe = new Stripe(secretKey);
  const rawBody = await request.text();

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
  } catch {
    return NextResponse.json({ error: "Invalid signature." }, { status: 400 });
  }

  const supabase = createServiceClient();

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session;
      const userId = session.metadata?.supabase_user_id;
      const subscriptionId = session.subscription ? String(session.subscription) : null;
      if (userId && subscriptionId) {
        await supabase
          .from("subscriptions")
          .update({
            plan: "premium",
            status: "active",
            stripe_subscription_id: subscriptionId,
          })
          .eq("user_id", userId);
        await supabase.from("profiles").update({ account_type: "premium" }).eq("id", userId);
      }
      break;
    }

    case "customer.subscription.updated": {
      const subscription = event.data.object as Stripe.Subscription;
      const status = statusFromStripe(subscription.status);
      // current_period_end now lives per line item, not on the subscription
      // itself (Stripe moved it for "flexible billing mode" — a
      // subscription can have items on different billing periods). This
      // app only ever creates single-item subscriptions, so the first item
      // is always the one that matters.
      const currentPeriodEnd = subscription.items.data[0]?.current_period_end;
      const periodEnd = currentPeriodEnd ? new Date(currentPeriodEnd * 1000).toISOString() : null;

      const { data: existing } = await supabase
        .from("subscriptions")
        .select("user_id")
        .eq("stripe_subscription_id", subscription.id)
        .maybeSingle();

      if (existing) {
        await supabase
          .from("subscriptions")
          .update({ status, current_period_end: periodEnd })
          .eq("user_id", existing.user_id);
        if (status !== "active") {
          await supabase
            .from("profiles")
            .update({ account_type: "free" })
            .eq("id", existing.user_id);
        }
      }
      break;
    }

    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription;
      const { data: existing } = await supabase
        .from("subscriptions")
        .select("user_id")
        .eq("stripe_subscription_id", subscription.id)
        .maybeSingle();

      if (existing) {
        await supabase
          .from("subscriptions")
          .update({ plan: "free", status: "canceled" })
          .eq("user_id", existing.user_id);
        await supabase.from("profiles").update({ account_type: "free" }).eq("id", existing.user_id);
      }
      break;
    }

    default:
      break;
  }

  return NextResponse.json({ received: true });
}
