"use server";

import Stripe from "stripe";
import { revalidatePath } from "next/cache";
import { redirect } from "@/i18n/navigation";
import { getLocale } from "next-intl/server";
import { createClient } from "@/lib/supabase/server";
import { createServiceClient } from "@/lib/supabase/service";

export type AccountResult = { ok: true } | { ok: false; error: string };

export async function updateProfile(formData: FormData): Promise<AccountResult> {
  const name = String(formData.get("name") ?? "").trim();
  if (!name) return { ok: false, error: "Name can't be empty." };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "You need to be signed in." };

  const { error } = await supabase.from("profiles").update({ name }).eq("id", user.id);
  if (error) return { ok: false, error: error.message };

  revalidatePath("/settings");
  revalidatePath("/dashboard");
  return { ok: true };
}

export async function changePassword(formData: FormData): Promise<AccountResult> {
  const newPassword = String(formData.get("newPassword") ?? "");
  const confirmPassword = String(formData.get("confirmPassword") ?? "");

  if (newPassword.length < 8) {
    return { ok: false, error: "Password must be at least 8 characters." };
  }
  if (newPassword !== confirmPassword) {
    return { ok: false, error: "Passwords don't match." };
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "You need to be signed in." };

  const { error } = await supabase.auth.updateUser({ password: newPassword });
  if (error) return { ok: false, error: error.message };

  return { ok: true };
}

/**
 * Permanently deletes the signed-in student's account — the "request
 * deletion" right the privacy policy promises. Cancels any active Stripe
 * subscription first (so nobody keeps getting charged for a deleted
 * account), then removes the auth user via the admin API, which cascades
 * through profiles -> lesson_progress/projects/certificates/subscriptions
 * via the existing "on delete cascade" foreign keys — no manual per-table
 * cleanup needed.
 */
export async function deleteAccount() {
  const locale = await getLocale();
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return redirect({ href: "/login", locale });

  const service = createServiceClient();

  const stripeKey = process.env.STRIPE_SECRET_KEY;
  if (stripeKey) {
    const { data: subscription } = await service
      .from("subscriptions")
      .select("stripe_subscription_id")
      .eq("user_id", user.id)
      .maybeSingle();

    if (subscription?.stripe_subscription_id) {
      const stripe = new Stripe(stripeKey);
      try {
        await stripe.subscriptions.cancel(subscription.stripe_subscription_id);
      } catch {
        // If Stripe already canceled it (or it's already gone), don't let
        // that block the account deletion the student actually asked for.
      }
    }
  }

  await service.auth.admin.deleteUser(user.id);
  await supabase.auth.signOut();

  redirect({ href: "/", locale });
}
