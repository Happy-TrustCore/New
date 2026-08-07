import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { Navbar } from "@/components/marketing/Navbar";
import { Footer } from "@/components/marketing/Footer";

const TRACK_KEYS = ["foundation", "frontend", "backend"] as const;
const METHOD_KEYS = ["learn", "use", "improve", "combine"] as const;

export default async function Home({
  params,
}: PageProps<"/[locale]">) {
  const { locale } = (await params) as { locale: Locale };
  setRequestLocale(locale);
  const t = await getTranslations("landing");

  return (
    <>
      <Navbar />
      <main className="flex-1">
        {/* Hero */}
        <section className="mx-auto flex max-w-6xl flex-col items-center gap-8 px-6 pb-20 pt-20 text-center sm:pt-28">
          <span className="rounded-full border border-border bg-surface px-4 py-1 text-xs text-muted">
            {t("hero.badge")}
          </span>
          <h1 className="max-w-3xl text-4xl font-bold tracking-tight sm:text-6xl">
            {t("hero.titlePrefix")} <span className="text-gradient">{t("hero.titleHighlight")}</span>
            {t("hero.titleSuffix")}
          </h1>
          <p className="max-w-2xl text-lg text-muted">{t("hero.subtitle")}</p>
          <div className="flex flex-wrap items-center justify-center gap-4">
            <Link
              href="/register"
              className="rounded-lg bg-accent px-6 py-3 font-semibold text-accent-foreground transition hover:opacity-90"
            >
              {t("hero.ctaPrimary")}
            </Link>
            <a
              href="#roadmap"
              className="rounded-lg border border-border px-6 py-3 font-semibold text-foreground transition hover:bg-surface"
            >
              {t("hero.ctaSecondary")}
            </a>
          </div>

          {/* mock editor */}
          <div className="mt-10 w-full max-w-2xl overflow-hidden rounded-xl border border-border bg-surface text-left shadow-2xl">
            <div className="flex items-center gap-1.5 border-b border-border px-4 py-3">
              <span className="h-3 w-3 rounded-full bg-red-500/70" />
              <span className="h-3 w-3 rounded-full bg-yellow-500/70" />
              <span className="h-3 w-3 rounded-full bg-green-500/70" />
              <span className="ml-3 font-mono text-xs text-muted">lesson-01.html</span>
            </div>
            <pre className="overflow-x-auto p-5 font-mono text-sm leading-relaxed">
              <code>
                <span className="text-muted">{"<h1>"}</span>
                {t("hero.codeSample")}
                <span className="text-accent"> Ahmed</span>
                <span className="text-muted">{"</h1>"}</span>
                {"\n"}
                <span className="text-muted">{"<p>"}</span>
                {t("hero.codeSampleP")}
                <span className="text-muted">{"</p>"}</span>
              </code>
            </pre>
          </div>
        </section>

        {/* How it works */}
        <section id="how-it-works" className="border-t border-border bg-surface/40 py-20">
          <div className="mx-auto max-w-6xl px-6">
            <h2 className="text-center text-3xl font-bold">{t("methods.title")}</h2>
            <p className="mx-auto mt-3 max-w-2xl text-center text-muted">
              {t("methods.subtitle")}
            </p>
            <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              {METHOD_KEYS.map((key, i) => (
                <div key={key} className="rounded-xl border border-border bg-surface p-6">
                  <span className="font-mono text-sm text-accent">0{i + 1}</span>
                  <h3 className="mt-2 text-lg font-semibold">{t(`methods.${key}.label`)}</h3>
                  <p className="mt-2 text-sm text-muted">{t(`methods.${key}.desc`)}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Roadmap */}
        <section id="roadmap" className="py-20">
          <div className="mx-auto max-w-6xl px-6">
            <h2 className="text-center text-3xl font-bold">{t("roadmap.title")}</h2>
            <p className="mx-auto mt-3 max-w-2xl text-center text-muted">
              {t("roadmap.subtitle")}
            </p>
            <div className="mt-12 grid gap-6 lg:grid-cols-3">
              {TRACK_KEYS.map((key, i) => (
                <div
                  key={key}
                  className="flex flex-col rounded-xl border border-border bg-surface p-6"
                >
                  <span className="font-mono text-sm text-muted">
                    0{i + 1}
                  </span>
                  <h3 className="mt-2 text-xl font-semibold">{t(`roadmap.${key}.title`)}</h3>
                  <p className="mt-2 text-sm text-muted">{t(`roadmap.${key}.tagline`)}</p>
                  <div className="mt-4 flex flex-wrap gap-2">
                    {t(`roadmap.${key}.tech`)
                      .split(",")
                      .map((tech) => (
                        <span
                          key={tech}
                          className="rounded-full border border-border bg-surface-2 px-3 py-1 text-xs font-mono text-foreground"
                        >
                          {tech}
                        </span>
                      ))}
                  </div>
                  <span className="mt-6 inline-block w-fit rounded-full bg-accent/10 px-3 py-1 text-xs font-semibold text-accent">
                    {t(`roadmap.${key}.access`)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Pricing */}
        <section id="pricing" className="border-t border-border bg-surface/40 py-20">
          <div className="mx-auto max-w-4xl px-6">
            <h2 className="text-center text-3xl font-bold">{t("pricing.title")}</h2>
            <p className="mx-auto mt-3 max-w-xl text-center text-muted">
              {t("pricing.subtitle")}
            </p>
            <div className="mt-12 grid gap-6 sm:grid-cols-2">
              <div className="rounded-xl border border-border bg-surface p-8">
                <h3 className="text-lg font-semibold">{t("pricing.free.title")}</h3>
                <p className="mt-1 text-3xl font-bold">€0</p>
                <ul className="mt-6 space-y-3 text-sm text-muted">
                  <li>✓ {t("pricing.free.item1")}</li>
                  <li>✓ {t("pricing.free.item2")}</li>
                  <li>✓ {t("pricing.free.item3")}</li>
                  <li>✓ {t("pricing.free.item4")}</li>
                </ul>
                <Link
                  href="/register"
                  className="mt-8 block rounded-lg border border-border py-2.5 text-center font-semibold hover:bg-surface-2"
                >
                  {t("pricing.free.cta")}
                </Link>
              </div>
              <div className="rounded-xl border border-accent/60 bg-surface p-8 shadow-[0_0_40px_-15px_var(--accent)]">
                <h3 className="text-lg font-semibold text-accent">{t("pricing.pro.title")}</h3>
                <p className="mt-1 text-3xl font-bold">
                  €4.99<span className="text-base font-normal text-muted">{t("pricing.pro.perMonth")}</span>
                </p>
                <ul className="mt-6 space-y-3 text-sm text-muted">
                  <li>✓ {t("pricing.pro.item1")}</li>
                  <li>✓ {t("pricing.pro.item2")}</li>
                  <li>✓ {t("pricing.pro.item3")}</li>
                  <li>✓ {t("pricing.pro.item4")}</li>
                </ul>
                <Link
                  href="/register"
                  className="mt-8 block rounded-lg bg-accent py-2.5 text-center font-semibold text-accent-foreground hover:opacity-90"
                >
                  {t("pricing.pro.cta")}
                </Link>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
