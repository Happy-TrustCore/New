import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { requestPasswordReset } from "@/lib/actions/auth";

export default async function ForgotPasswordPage({
  params,
  searchParams,
}: PageProps<"/[locale]/forgot-password">) {
  const { locale } = (await params) as { locale: Locale };
  setRequestLocale(locale);
  const t = await getTranslations("auth.forgotPassword");

  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;

  return (
    <main className="flex flex-1 items-center justify-center px-6 py-16">
      <div className="w-full max-w-sm">
        <Link href="/login" className="font-mono text-sm text-muted transition hover:text-foreground">
          &larr; {t("backLogin")}
        </Link>

        <div className="card animate-float-in mt-4 p-7">
          <h1 className="text-2xl font-bold">
            <span className="text-gradient">{t("title")}</span>
          </h1>
          <p className="mt-1 text-sm text-muted">{t("subtitle")}</p>

          {error && (
            <p className="mt-4 rounded-lg border border-danger/40 bg-danger/10 px-4 py-2 text-sm text-danger">
              {error}
            </p>
          )}

          <form action={requestPasswordReset} className="mt-6 space-y-4">
            <div>
              <label htmlFor="email" className="text-sm text-muted">
                {t("email")}
              </label>
              <input
                id="email"
                name="email"
                type="email"
                required
                className="mt-1 w-full rounded-lg border border-border bg-surface-2/60 px-3 py-2 outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20"
              />
            </div>
            <button type="submit" className="btn-primary w-full rounded-lg py-2.5">
              {t("submit")}
            </button>
          </form>
        </div>
      </div>
    </main>
  );
}
