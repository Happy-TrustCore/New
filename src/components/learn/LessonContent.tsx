"use client";

import { useState } from "react";
import { useLocale, useTranslations } from "next-intl";
import type { Difficulty, LessonContentBlock, LocalizedText } from "@/lib/supabase/types";
import { pickLocale } from "@/lib/i18n-content";

export function LessonContent({
  title,
  difficulty,
  steps,
}: {
  title: LocalizedText;
  difficulty: Difficulty;
  steps: LessonContentBlock[];
}) {
  const [stepIndex, setStepIndex] = useState(0);
  const locale = useLocale();
  const t = useTranslations("learn.content");
  const step = steps[stepIndex];
  const isLast = stepIndex === steps.length - 1;

  return (
    <div className="p-6">
      <span className="w-fit rounded-full border border-border bg-surface-2 px-3 py-1 text-xs font-mono text-muted">
        {t(`difficulty.${difficulty}`)}
      </span>
      <h1 className="mt-3 text-2xl font-bold">{pickLocale(title, locale)}</h1>

      {step && (
        <div className="mt-6 rounded-xl border border-border bg-surface p-6">
          <p className="text-xs font-mono text-muted">
            {t("stepOf", { current: stepIndex + 1, total: steps.length })}
          </p>
          <p className="mt-3 whitespace-pre-line leading-relaxed text-foreground">
            {pickLocale(step.text, locale)}
          </p>
        </div>
      )}

      <div className="mt-4 flex items-center gap-3">
        {stepIndex > 0 && (
          <button
            onClick={() => setStepIndex((i) => Math.max(0, i - 1))}
            className="rounded-lg border border-border px-4 py-2 text-sm font-semibold hover:bg-surface-2"
          >
            &larr; {t("back")}
          </button>
        )}
        {!isLast && (
          <button
            onClick={() => setStepIndex((i) => Math.min(steps.length - 1, i + 1))}
            className="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-accent-foreground hover:opacity-90"
          >
            {t("continue")} &rarr;
          </button>
        )}
      </div>
    </div>
  );
}
