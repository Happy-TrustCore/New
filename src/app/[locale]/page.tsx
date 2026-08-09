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
          <span className="animate-float-in glass px-4 py-1.5 text-xs text-muted shadow-lg">
            {t("hero.badge")}
          </span>
          <h1 className="animate-float-in max-w-3xl text-4xl font-bold tracking-tight sm:text-6xl md:text-7xl">
            {t("hero.titlePrefix")} <span className="text-gradient">{t("hero.titleHighlight")}</span>
            {t("hero.titleSuffix")}
          </h1>
          <p className="animate-float-in max-w-2xl text-lg text-muted">{t("hero.subtitle")}</p>
          <div className="animate-float-in flex flex-wrap items-center justify-center gap-4">
            <Link
              href="/register"
              className="btn-primary rounded-lg px-6 py-3"
            >
              {t("hero.ctaPrimary")}
            </Link>
            <a
              href="#roadmap"
              className="rounded-lg border border-border px-6 py-3 font-semibold text-foreground transition hover:border-border-strong hover:bg-surface"
            >
              {t("hero.ctaSecondary")}
            </a>
          </div>

          {/* mock editor — a real two-pane editor+live-preview, matching the
              actual /learn product, not an abstract decorative code block */}
          <div className="relative mt-14 w-full max-w-3xl">
            <div className="glow-accent card animate-float-in grid overflow-hidden text-left sm:grid-cols-2">
              <div className="border-b border-border sm:border-b-0 sm:border-r">
                <div className="flex items-center gap-1.5 border-b border-border bg-surface-2 px-4 py-3">
                  <span className="h-3 w-3 rounded-full bg-red-500/70" />
                  <span className="h-3 w-3 rounded-full bg-yellow-500/70" />
                  <span className="h-3 w-3 rounded-full bg-green-500/70" />
                  <span className="ml-3 font-mono text-xs text-muted">lesson-01.html</span>
                </div>
                <pre className="overflow-x-auto p-5 font-mono text-[13px] leading-relaxed">
                  <code>
                    <span className="text-accent-2">{"<h1>"}</span>
                    {t("hero.codeSample")}
                    <span className="text-accent"> Ahmed</span>
                    <span className="text-accent-2">{"</h1>"}</span>
                    {"\n"}
                    <span className="text-accent-2">{"<p>"}</span>
                    {t("hero.codeSampleP")}
                    <span className="text-accent-2">{"</p>"}</span>
                  </code>
                </pre>
              </div>
              <div className="bg-background/40">
                <div className="flex items-center gap-1.5 border-b border-border bg-surface-2 px-4 py-3">
                  <span className="font-mono text-xs text-muted">{t("hero.previewLabel")}</span>
                  <span className="ml-auto flex items-center gap-1.5 font-mono text-[10px] text-accent">
                    <span className="animate-pulse-dot h-1.5 w-1.5 rounded-full bg-accent" />
                    live
                  </span>
                </div>
                <div className="flex h-full flex-col gap-2 p-5">
                  <p className="text-lg font-bold">
                    {t("hero.codeSample")} <span className="text-accent">Ahmed</span>
                  </p>
                  <p className="text-sm text-muted">{t("hero.codeSampleP")}</p>
                </div>
              </div>
            </div>

            {/* floating badges — a quick, glanceable hint of the XP/streak
                system without requiring the visitor to read anything */}
            <div className="glass animate-bob absolute -left-6 -top-6 hidden rounded-xl px-4 py-2.5 shadow-2xl sm:flex sm:items-center sm:gap-2">
              <span className="text-lg">🔥</span>
              <span className="font-mono text-xs font-semibold">{t("hero.streakBadge")}</span>
            </div>
            <div
              className="glass animate-bob absolute -bottom-5 -right-4 hidden rounded-xl px-4 py-2.5 shadow-2xl sm:flex sm:items-center sm:gap-2"
              style={{ animationDelay: "1.2s" }}
            >
              <span className="text-lg">✓</span>
              <span className="font-mono text-xs font-semibold text-accent">{t("hero.xpBadge")}</span>
            </div>
          </div>
        </section>

        {/* Stats */}
        <div className="mx-auto max-w-5xl px-6">
          <div className="section-fade" />
        </div>
        <section className="py-12">
          <div className="mx-auto grid max-w-5xl grid-cols-2 gap-8 px-6 sm:grid-cols-4">
            {[
              { value: "63", label: t("stats.lessons"), color: "text-accent" },
              { value: "28", label: t("stats.free"), color: "text-accent-2" },
              { value: "3", label: t("stats.tracks"), color: "text-accent-3" },
              { value: "2", label: t("stats.languages"), color: "text-accent-warm" },
            ].map((stat) => (
              <div key={stat.label} className="card card-hover px-4 py-6 text-center">
                <p className={`text-3xl font-bold sm:text-4xl ${stat.color}`}>{stat.value}</p>
                <p className="mt-1 text-xs text-muted sm:text-sm">{stat.label}</p>
              </div>
            ))}
          </div>
        </section>

        {/* How it works */}
        <div className="mx-auto max-w-6xl px-6">
          <div className="section-fade" />
        </div>
        <section id="how-it-works" className="bg-surface/40 py-20">
          <div className="mx-auto max-w-6xl px-6">
            <h2 className="text-center text-3xl font-bold">{t("methods.title")}</h2>
            <p className="mx-auto mt-3 max-w-2xl text-center text-muted">
              {t("methods.subtitle")}
            </p>
            <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              {METHOD_KEYS.map((key, i) => {
                const colors = ["text-accent", "text-accent-2", "text-accent-3", "text-accent-warm"];
                return (
                  <div key={key} className="card card-hover p-6">
                    <span className={`font-mono text-sm font-semibold ${colors[i % colors.length]}`}>
                      0{i + 1}
                    </span>
                    <h3 className="mt-2 text-lg font-semibold">{t(`methods.${key}.label`)}</h3>
                    <p className="mt-2 text-sm text-muted">{t(`methods.${key}.desc`)}</p>
                  </div>
                );
              })}
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
              {TRACK_KEYS.map((key, i) => {
                const styles = [
                  { text: "text-accent", badge: "bg-accent/10 text-accent" },
                  { text: "text-accent-2", badge: "bg-accent-2/10 text-accent-2" },
                  { text: "text-accent-3", badge: "bg-accent-3/10 text-accent-3" },
                ];
                const style = styles[i % styles.length];
                return (
                  <div key={key} className="card card-hover flex flex-col p-6">
                    <span className={`font-mono text-sm font-semibold ${style.text}`}>
                      0{i + 1}
                    </span>
                    <h3 className="mt-2 text-xl font-semibold">{t(`roadmap.${key}.title`)}</h3>
                    <p className="mt-2 text-sm text-muted">{t(`roadmap.${key}.tagline`)}</p>
                    <div className="mt-4 flex flex-wrap gap-2">
                      {t(`roadmap.${key}.tech`)
                        .split(",")
                        .map((tech) => (
                          <span key={tech} className="pill px-3 py-1 text-xs font-mono text-foreground">
                            {tech}
                          </span>
                        ))}
                    </div>
                    <span className={`mt-6 inline-block w-fit rounded-full px-3 py-1 text-xs font-semibold ${style.badge}`}>
                      {t(`roadmap.${key}.access`)}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        </section>

        {/* Pricing */}
        <div className="mx-auto max-w-4xl px-6">
          <div className="section-fade" />
        </div>
        <section id="pricing" className="bg-surface/40 py-20">
          <div className="mx-auto max-w-4xl px-6">
            <h2 className="text-center text-3xl font-bold">{t("pricing.title")}</h2>
            <p className="mx-auto mt-3 max-w-xl text-center text-muted">
              {t("pricing.subtitle")}
            </p>
            <div className="mt-12 grid gap-6 sm:grid-cols-2">
              <div className="card p-8">
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
                  className="mt-8 block rounded-lg border border-border py-2.5 text-center font-semibold transition hover:border-border-strong hover:bg-surface-2"
                >
                  {t("pricing.free.cta")}
                </Link>
              </div>
              <div className="glow-accent card p-8" style={{ borderColor: "color-mix(in srgb, var(--accent) 55%, var(--border))" }}>
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
                  className="btn-primary mt-8 block rounded-lg py-2.5 text-center"
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
