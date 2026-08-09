"use server";

import { redirect as plainRedirect } from "next/navigation";
import { headers } from "next/headers";
import { redirect } from "@/i18n/navigation";
import { getLocale } from "next-intl/server";
import { routing } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";

export async function signUp(formData: FormData) {
  const locale = await getLocale();
  const name = String(formData.get("name") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");

  if (!name || !email || !password) {
    redirect({
      href: `/register?error=${encodeURIComponent("All fields are required.")}`,
      locale,
    });
  }
  if (password.length < 8) {
    redirect({
      href: `/register?error=${encodeURIComponent(
        "Password must be at least 8 characters."
      )}`,
      locale,
    });
  }

  const headerList = await headers();
  const host = headerList.get("host") ?? "";
  const protocol = headerList.get("x-forwarded-proto") ?? (host.startsWith("localhost") ? "http" : "https");
  const origin = headerList.get("origin") ?? `${protocol}://${host}`;
  const confirmedPath = locale === routing.defaultLocale ? "/confirmed" : `/${locale}/confirmed`;

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { name }, emailRedirectTo: `${origin}${confirmedPath}` },
  });

  if (error) {
    redirect({ href: `/register?error=${encodeURIComponent(error.message)}`, locale });
  }

  if (data.session) {
    redirect({ href: "/dashboard", locale });
  }

  redirect({
    href: `/login?notice=${encodeURIComponent(
      "Account created. Check your email to confirm it, then log in."
    )}`,
    locale,
  });
}

export async function signIn(formData: FormData) {
  const locale = await getLocale();
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const next = String(formData.get("next") ?? "/dashboard");

  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    redirect({
      href: `/login?error=${encodeURIComponent(
        "Incorrect email or password."
      )}&next=${encodeURIComponent(next)}`,
      locale,
    });
  }

  // `next` is already a fully-resolved, locale-correct path captured from the
  // original request URL (see src/lib/supabase/proxy.ts) — don't re-localize it.
  plainRedirect(next);
}

export async function signOut() {
  const locale = await getLocale();
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect({ href: "/", locale });
}

export async function requestPasswordReset(formData: FormData) {
  const locale = await getLocale();
  const email = String(formData.get("email") ?? "").trim();

  if (!email) {
    redirect({
      href: `/forgot-password?error=${encodeURIComponent("Enter your email address.")}`,
      locale,
    });
  }

  const headerList = await headers();
  const host = headerList.get("host") ?? "";
  const protocol = headerList.get("x-forwarded-proto") ?? (host.startsWith("localhost") ? "http" : "https");
  const origin = headerList.get("origin") ?? `${protocol}://${host}`;
  const resetPath =
    locale === routing.defaultLocale ? "/reset-password" : `/${locale}/reset-password`;

  const supabase = await createClient();
  await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${origin}${resetPath}`,
  });

  // Deliberately the same message whether or not the email exists — Supabase
  // itself doesn't reveal that either, so don't let this page leak it.
  redirect({
    href: `/login?notice=${encodeURIComponent(
      "If that email has an account, a reset link is on its way."
    )}`,
    locale,
  });
}
