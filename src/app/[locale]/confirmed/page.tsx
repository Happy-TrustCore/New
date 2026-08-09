"use client";

import { useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { useRouter, Link } from "@/i18n/navigation";
import { createClient } from "@/lib/supabase/client";

export default function ConfirmedPage() {
  const t = useTranslations("auth.confirmed");
  const router = useRouter();
  const [hasSession, setHasSession] = useState<boolean | null>(null);

  useEffect(() => {
    const supabase = createClient();
    supabase.auth.getSession().then(({ data }) => {
      setHasSession(!!data.session);
      if (data.session) {
        const timeout = setTimeout(() => router.push("/dashboard"), 1800);
        return () => clearTimeout(timeout);
      }
    });
  }, [router]);

  return (
    <main className="flex flex-1 items-center justify-center px-6 py-16">
      <div className="glow-accent card w-full max-w-sm p-8 text-center">
        <span className="text-3xl">✅</span>
        <h1 className="mt-3 text-xl font-bold">{t("title")}</h1>
        {hasSession ? (
          <p className="mt-2 text-sm text-muted">{t("redirecting")}</p>
        ) : (
          <>
            <p className="mt-2 text-sm text-muted">{t("body")}</p>
            <Link href="/login" className="btn-primary mt-6 inline-block rounded-lg px-5 py-2.5 text-sm">
              {t("login")}
            </Link>
          </>
        )}
      </div>
    </main>
  );
}
