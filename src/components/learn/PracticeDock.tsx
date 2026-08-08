"use client";

import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { CodeWorkspace } from "./CodeWorkspace";
import type { StarterCode } from "@/lib/supabase/types";

export function PracticeDock({
  open,
  onToggle,
  paywalled,
  lessonId,
  starterCode,
  practicePassed,
  hasAssignment,
  assignmentPassed,
}: {
  open: boolean;
  onToggle: () => void;
  paywalled: boolean;
  lessonId: string;
  starterCode: StarterCode | null;
  practicePassed: boolean;
  hasAssignment: boolean;
  assignmentPassed: boolean;
}) {
  const t = useTranslations("learn.dock");

  if (paywalled) {
    return (
      <div className="shrink-0 border-t border-border bg-surface p-4 text-center">
        <p className="text-sm text-muted">{t("paywall")}</p>
        <Link href="/#pricing" className="btn-primary mt-2 inline-block rounded-lg px-4 py-1.5 text-sm">
          {t("upgrade")}
        </Link>
      </div>
    );
  }

  return (
    <div
      className={`shrink-0 border-t border-border bg-[#1e1e1e] shadow-[0_-20px_40px_-20px_rgba(0,0,0,0.6)] transition-[height] duration-300 ease-out ${
        open ? "h-[min(65vh,560px)]" : "h-12"
      }`}
    >
      <button
        onClick={onToggle}
        className="flex h-12 w-full items-center justify-between px-4 text-sm font-semibold text-foreground transition hover:bg-white/5"
      >
        <span className="flex items-center gap-2">
          <span className={`inline-block transition-transform ${open ? "rotate-180" : ""}`}>▲</span>
          {t("title")}
          {practicePassed && <span className="text-accent">✓</span>}
        </span>
        <span className="font-mono text-xs text-muted">{open ? t("collapse") : t("expand")}</span>
      </button>
      {open && (
        <div className="h-[calc(100%-3rem)] border-t border-black/40">
          <CodeWorkspace
            lessonId={lessonId}
            starterCode={starterCode}
            practicePassed={practicePassed}
            hasAssignment={hasAssignment}
            assignmentPassed={assignmentPassed}
          />
        </div>
      )}
    </div>
  );
}
