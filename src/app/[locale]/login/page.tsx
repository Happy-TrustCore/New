import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { routing, type Locale } from "@/i18n/routing";
import { signIn } from "@/lib/actions/auth";

export default async function LoginPage({
  params,
  searchParams,
}: PageProps<"/[locale]/login">) {
  const { locale } = (await params) as { locale: Locale };
  setRequestLocale(locale);
  const t = await getTranslations("auth.login");

  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;
  const notice = typeof sp.notice === "string" ? sp.notice : null;
  const defaultNext = locale === routing.defaultLocale ? "/dashboard" : `/${locale}/dashboard`;
  const next = typeof sp.next === "string" ? sp.next : defaultNext;

  return (
    <main className="flex flex-1 items-center justify-center px-6 py-16">
      <div className="w-full max-w-sm">
        <Link href="/" className="font-mono text-sm text-muted">
          &larr; {t("backHome")}
        </Link>
        <h1 className="mt-4 text-2xl font-bold">{t("title")}</h1>
        <p className="mt-1 text-sm text-muted">{t("subtitle")}</p>

        {notice && (
          <p className="mt-4 rounded-lg border border-accent/40 bg-accent/10 px-4 py-2 text-sm text-accent">
            {notice}
          </p>
        )}
        {error && (
          <p className="mt-4 rounded-lg border border-red-500/40 bg-red-500/10 px-4 py-2 text-sm text-red-400">
            {error}
          </p>
        )}

        <form action={signIn} className="mt-6 space-y-4">
          <input type="hidden" name="next" value={next} />
          <div>
            <label htmlFor="email" className="text-sm text-muted">
              {t("email")}
            </label>
            <input
              id="email"
              name="email"
              type="email"
              required
              className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 outline-none focus:border-accent"
            />
          </div>
          <div>
            <div className="flex items-center justify-between">
              <label htmlFor="password" className="text-sm text-muted">
                {t("password")}
              </label>
              <Link href="/forgot-password" className="text-xs text-accent hover:underline">
                {t("forgotPassword")}
              </Link>
            </div>
            <input
              id="password"
              name="password"
              type="password"
              required
              className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 outline-none focus:border-accent"
            />
          </div>
          <button
            type="submit"
            className="w-full rounded-lg bg-accent py-2.5 font-semibold text-accent-foreground transition hover:opacity-90"
          >
            {t("submit")}
          </button>
        </form>

        <p className="mt-6 text-center text-sm text-muted">
          {t("newHere")}{" "}
          <Link href="/register" className="text-accent">
            {t("startFree")}
          </Link>
        </p>
      </div>
    </main>
  );
}
