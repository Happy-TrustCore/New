"use client";

import { useState } from "react";
import { useLocale, useTranslations } from "next-intl";
import type { Difficulty, LessonContentBlock, LocalizedText } from "@/lib/supabase/types";
import { pickLocale } from "@/lib/i18n-content";
import { QuickCheck } from "./QuickCheck";

const DIFFICULTY_COLOR: Record<Difficulty, string> = {
  beginner: "text-accent",
  intermediate: "text-accent-warm",
  advanced: "text-danger",
};

const DIFFICULTY_BORDER: Record<Difficulty, string> = {
  beginner: "border-l-accent",
  intermediate: "border-l-accent-warm",
  advanced: "border-l-danger",
};

export function LessonContent({
  title,
  difficulty,
  steps,
  onStartPractice,
  isAdmin = false,
}: {
  title: LocalizedText;
  difficulty: Difficulty;
  steps: LessonContentBlock[];
  onStartPractice: () => void;
  isAdmin?: boolean;
}) {
  const [stepIndex, setStepIndex] = useState(0);
  // Tracks the step index whose quick check has been passed, rather than a
  // plain boolean — a new step index simply won't match this, which resets
  // "passed" for free on navigation without needing an effect to do it.
  const [checkPassedStep, setCheckPassedStep] = useState<number | null>(null);
  const locale = useLocale();
  const t = useTranslations("learn.content");
  const step = steps[stepIndex];
  const isLast = stepIndex === steps.length - 1;
  // Admins can always browse freely — quick-check questions are a learning
  // gate for students, not an access-control check, so they don't apply here.
  const canContinue = isAdmin || !step?.check || checkPassedStep === stepIndex;

  return (
    <div className="animate-float-in p-6">
      <div className="flex items-center gap-3">
        <span className={`pill w-fit px-3 py-1 text-xs font-mono ${DIFFICULTY_COLOR[difficulty]}`}>
          {t(`difficulty.${difficulty}`)}
        </span>
        <span className="h-px flex-1 bg-gradient-to-r from-border to-transparent" />
      </div>
      <h1 className="mt-3 text-2xl font-bold sm:text-3xl">
        <span className="text-gradient">{pickLocale(title, locale)}</span>
      </h1>

      <div className="mt-4 flex gap-1.5">
        {steps.map((_, i) => {
          const visited = i <= stepIndex;
          return (
            <button
              key={i}
              onClick={() => visited && setStepIndex(i)}
              disabled={!visited}
              aria-label={t("stepOf", { current: i + 1, total: steps.length })}
              className={`h-1.5 flex-1 rounded-full transition-all duration-300 ${
                visited ? "bg-accent hover:h-2 disabled:hover:h-1.5" : "bg-border"
              } ${visited && i !== stepIndex ? "cursor-pointer" : "cursor-default"}`}
            />
          );
        })}
      </div>

      {step && (
        <div
          key={stepIndex}
          className={`card animate-float-in mt-4 border-l-4 p-6 ${DIFFICULTY_BORDER[difficulty]}`}
        >
          <p className="flex items-center gap-2 text-xs font-mono text-muted">
            <span
              className={`flex h-5 w-5 items-center justify-center rounded-full bg-surface-2 text-[10px] font-semibold ${DIFFICULTY_COLOR[difficulty]}`}
            >
              {stepIndex + 1}
            </span>
            {t("stepOf", { current: stepIndex + 1, total: steps.length })}
          </p>
          <p className="mt-3 whitespace-pre-line text-base leading-relaxed text-foreground">
            {pickLocale(step.text, locale)}
          </p>

          {step.check && (
            <QuickCheck check={step.check} onPassed={() => setCheckPassedStep(stepIndex)} />
          )}
        </div>
      )}

      {isLast && canContinue && (
        <p className="animate-float-in mt-3 flex items-center gap-1.5 text-xs text-accent">
          🎯 {t("readyForPractice")}
        </p>
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
        {!isLast ? (
          <button
            onClick={() => setStepIndex((i) => Math.min(steps.length - 1, i + 1))}
            disabled={!canContinue}
            className="btn-primary rounded-lg px-4 py-2 text-sm disabled:cursor-not-allowed disabled:opacity-40"
          >
            {t("continue")} &rarr;
          </button>
        ) : (
          <button
            onClick={onStartPractice}
            disabled={!canContinue}
            className="btn-primary rounded-lg px-4 py-2 text-sm disabled:cursor-not-allowed disabled:opacity-40"
          >
            {t("startPractice")} &rarr;
          </button>
        )}
        {step?.check && !canContinue && (
          <p className="text-xs text-muted">{t("answerToContinue")}</p>
        )}
      </div>
    </div>
  );
}
