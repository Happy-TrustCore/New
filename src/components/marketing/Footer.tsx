import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";

export function Footer() {
  const t = useTranslations("footer");

  return (
    <footer className="border-t border-border bg-surface/30 py-10">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 text-sm text-muted sm:flex-row">
        <p className="font-mono">
          &lt;/&gt; CodePath<span className="text-gradient">Academy</span>
        </p>
        <p>{t("tagline")}</p>
        <div className="flex items-center gap-4">
          <Link href="/privacy" className="hover:text-foreground">
            {t("privacy")}
          </Link>
          <Link href="/terms" className="hover:text-foreground">
            {t("terms")}
          </Link>
        </div>
        <p>&copy; {new Date().getFullYear()} CodePath Academy</p>
      </div>
    </footer>
  );
}
