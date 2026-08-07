"use client";

import { useState, useTransition } from "react";
import { useLocale, useTranslations } from "next-intl";
import { useRouter } from "@/i18n/navigation";
import { submitQuiz } from "@/lib/actions/quiz";
import type { LocalizedChoices, LocalizedText } from "@/lib/supabase/types";
import { pickLocale, pickLocaleChoices } from "@/lib/i18n-content";

type QuizQuestionPublic = {
  id: string;
  question: LocalizedText;
  choices: LocalizedChoices;
};

export function QuizPanel({
  lessonId,
  questions,
  alreadyPassed,
}: {
  lessonId: string;
  questions: QuizQuestionPublic[];
  alreadyPassed: boolean;
}) {
  const router = useRouter();
  const locale = useLocale();
  const t = useTranslations("learn.quiz");
  const [isPending, startTransition] = useTransition();
  const [answers, setAnswers] = useState<number[]>(() => questions.map(() => -1));
  const [result, setResult] = useState<{ passed: boolean; correctCount: number; total: number } | null>(
    null
  );

  const allAnswered = answers.every((a) => a >= 0);

  function handleSubmit() {
    startTransition(async () => {
      const response = await submitQuiz(lessonId, answers);
      if (!response.ok) return;
      setResult({
        passed: response.passed,
        correctCount: response.correctCount,
        total: response.total,
      });
      if (response.passed) {
        router.refresh();
      }
    });
  }

  return (
    <div className="border-t border-border p-6">
      <p className="text-sm font-semibold text-accent">{t("title")}</p>
      {alreadyPassed && !result && (
        <p className="mt-1 text-xs text-muted">{t("alreadyPassed")}</p>
      )}

      <div className="mt-4 space-y-6">
        {questions.map((q, qi) => {
          const choices = pickLocaleChoices(q.choices, locale);
          return (
            <div key={q.id}>
              <p className="text-sm font-medium">{pickLocale(q.question, locale)}</p>
              <div className="mt-2 space-y-2">
                {choices.map((choice, ci) => (
                  <button
                    key={ci}
                    onClick={() =>
                      setAnswers((prev) => prev.map((a, i) => (i === qi ? ci : a)))
                    }
                    className={`block w-full rounded-lg border px-3 py-2 text-left text-sm ${
                      answers[qi] === ci
                        ? "border-accent bg-accent/10 text-accent"
                        : "border-border bg-surface hover:bg-surface-2"
                    }`}
                  >
                    {choice}
                  </button>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      <button
        onClick={handleSubmit}
        disabled={!allAnswered || isPending}
        className="mt-6 w-full rounded-lg bg-accent py-2.5 text-sm font-semibold text-accent-foreground transition hover:opacity-90 disabled:opacity-50"
      >
        {isPending ? t("checking") : t("submit")}
      </button>

      {result && (
        <p className={`mt-3 text-sm ${result.passed ? "text-accent" : "text-red-400"}`}>
          {result.passed
            ? t("passed", { correct: result.correctCount, total: result.total })
            : t("failed", { correct: result.correctCount, total: result.total })}
        </p>
      )}
    </div>
  );
}
