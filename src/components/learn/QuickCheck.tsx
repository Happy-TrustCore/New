"use client";

import { useState } from "react";
import { useLocale, useTranslations } from "next-intl";
import type { LessonQuickCheck } from "@/lib/supabase/types";
import { pickLocale, pickLocaleChoices } from "@/lib/i18n-content";

export function QuickCheck({
  check,
  onPassed,
}: {
  check: LessonQuickCheck;
  onPassed: () => void;
}) {
  const locale = useLocale();
  const t = useTranslations("learn.content");
  const [selected, setSelected] = useState<number | null>(null);
  const [result, setResult] = useState<"correct" | "incorrect" | null>(null);
  const choices = pickLocaleChoices(check.choices, locale);

  function handleSelect(i: number) {
    if (result === "correct") return;
    setSelected(i);
    if (i === check.correctIndex) {
      setResult("correct");
      onPassed();
    } else {
      setResult("incorrect");
    }
  }

  return (
    <div className="mt-5 rounded-xl border border-accent-3/40 bg-accent-3/5 p-5">
      <p className="flex items-center gap-1.5 text-xs font-mono font-semibold uppercase tracking-wide text-accent-3">
        ⚡ {t("quickCheck")}
      </p>
      <p className="mt-2 text-sm font-medium text-foreground">{pickLocale(check.question, locale)}</p>
      <div className="mt-3 space-y-2">
        {choices.map((choice, i) => {
          const isSelected = selected === i;
          const isCorrectChoice = i === check.correctIndex;
          const revealed = result !== null && isSelected;
          return (
            <button
              key={i}
              onClick={() => handleSelect(i)}
              disabled={result === "correct"}
              className={`block w-full rounded-lg border px-3 py-2 text-left text-sm transition ${
                revealed && isCorrectChoice
                  ? "border-accent bg-accent/10 text-accent"
                  : revealed
                  ? "border-danger bg-danger/10 text-danger"
                  : "border-border bg-surface hover:border-border-strong hover:bg-surface-2"
              }`}
            >
              {choice}
            </button>
          );
        })}
      </div>
      {result === "incorrect" && <p className="mt-2 text-xs text-danger">{t("tryAgain")}</p>}
      {result === "correct" && <p className="mt-2 text-xs text-accent">✓ {t("niceWork")}</p>}
    </div>
  );
}
