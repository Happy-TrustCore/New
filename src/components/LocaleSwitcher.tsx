"use client";

import { useLocale } from "next-intl";
import { usePathname, useRouter } from "@/i18n/navigation";
import { routing } from "@/i18n/routing";

export function LocaleSwitcher() {
  const locale = useLocale();
  const pathname = usePathname();
  const router = useRouter();

  return (
    <div className="flex items-center gap-1 rounded-full border border-border bg-surface p-0.5 text-xs">
      {routing.locales.map((code) => (
        <button
          key={code}
          onClick={() => router.replace(pathname, { locale: code })}
          disabled={code === locale}
          className={`rounded-full px-2 py-1 font-mono uppercase transition ${
            code === locale
              ? "bg-accent text-accent-foreground"
              : "text-muted hover:text-foreground"
          }`}
        >
          {code}
        </button>
      ))}
    </div>
  );
}
