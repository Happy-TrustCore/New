"use client";

import { useEffect, useState } from "react";
import { useLocale, useTranslations } from "next-intl";
import type { Difficulty, LessonContentBlock, LocalizedText } from "@/lib/supabase/types";
import { pickLocale } from "@/lib/i18n-content";

const DIFFICULTY_COLOR: Record<Difficulty, string> = {
  beginner: "text-accent",
  intermediate: "text-accent-warm",
  advanced: "text-danger",
};

export function LessonContent({
  title,
  difficulty,
  steps,
  onReachLast,
}: {
  title: LocalizedText;
  difficulty: Difficulty;
  steps: LessonContentBlock[];
  onReachLast?: () => void;
}) {
  const [stepIndex, setStepIndex] = useState(0);
  const locale = useLocale();
  const t = useTranslations("learn.content");
  const step = steps[stepIndex];
  const isLast = stepIndex === steps.length - 1;

  useEffect(() => {
    if (isLast) onReachLast?.();
  }, [isLast, onReachLast]);

  return (
    <div className="animate-float-in p-6">
      <span className={`pill w-fit px-3 py-1 text-xs font-mono ${DIFFICULTY_COLOR[difficulty]}`}>
        {t(`difficulty.${difficulty}`)}
      </span>
      <h1 className="mt-3 text-2xl font-bold">{pickLocale(title, locale)}</h1>

      <div className="mt-4 flex gap-1.5">
        {steps.map((_, i) => (
          <span
            key={i}
            className={`h-1.5 flex-1 rounded-full transition-colors ${
              i <= stepIndex ? "bg-accent" : "bg-border"
            }`}
          />
        ))}
      </div>

      {step && (
        <div key={stepIndex} className="card animate-float-in mt-4 p-6">
          <p className="text-xs font-mono text-muted">
            {t("stepOf", { current: stepIndex + 1, total: steps.length })}
          </p>
          <p className="mt-3 whitespace-pre-line text-base leading-relaxed text-foreground">
            {pickLocale(step.text, locale)}
          </p>
        </div>
      )}

      <div className="mt-4 flex items-center gap-3">
        {stepIndex > 0 && (
          <button
            onClick={() => setStepIndex((i) => Math.max(0, i - 1))}
            className="rounded-lg border border-border px-4 py-2 text-sm font-semibold transition hover:border-border-strong hover:bg-surface-2"
          >
            &larr; {t("back")}
          </button>
        )}
        {!isLast && (
          <button
            onClick={() => setStepIndex((i) => Math.min(steps.length - 1, i + 1))}
            className="btn-primary rounded-lg px-4 py-2 text-sm"
          >
            {t("continue")} &rarr;
          </button>
        )}
      </div>
    </div>
  );
}
