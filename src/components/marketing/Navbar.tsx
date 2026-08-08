import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { LocaleSwitcher } from "@/components/LocaleSwitcher";

export function Navbar() {
  const t = useTranslations("nav");

  return (
    <header className="sticky top-0 z-40 border-b border-border/80 bg-background/70 backdrop-blur-xl">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/" className="flex items-center gap-2 font-mono text-lg font-semibold transition hover:opacity-90">
          <span className="text-accent-3">&lt;/&gt;</span>
          CodePath<span className="text-gradient">Academy</span>
        </Link>

        <nav className="hidden items-center gap-8 text-sm text-muted md:flex">
          <a href="#roadmap" className="hover:text-foreground">
            {t("roadmap")}
          </a>
          <a href="#how-it-works" className="hover:text-foreground">
            {t("howItWorks")}
          </a>
          <a href="#pricing" className="hover:text-foreground">
            {t("pricing")}
          </a>
        </nav>

        <div className="flex items-center gap-3">
          <LocaleSwitcher />
          <Link
            href="/login"
            className="hidden text-sm text-muted hover:text-foreground sm:block"
          >
            {t("login")}
          </Link>
          <Link
            href="/register"
            className="btn-primary rounded-lg px-4 py-2 text-sm"
          >
            {t("startFree")}
          </Link>
        </div>
      </div>
    </header>
  );
}
