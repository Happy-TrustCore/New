"use server";

import { redirect as plainRedirect } from "next/navigation";
import { redirect } from "@/i18n/navigation";
import { getLocale } from "next-intl/server";
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

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { name } },
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
