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
  onPassed,
}: {
  lessonId: string;
  questions: QuizQuestionPublic[];
  alreadyPassed: boolean;
  onPassed?: () => void;
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
        onPassed?.();
      }
    });
  }

  return (
    <div>
      <div className="flex items-center gap-3">
        <span className="pill w-fit px-3 py-1 text-xs font-mono text-accent">{t("title")}</span>
        <span className="h-px flex-1 bg-gradient-to-r from-border to-transparent" />
      </div>
      {alreadyPassed && !result && (
        <p className="mt-2 text-xs text-muted">{t("alreadyPassed")}</p>
      )}

      <div className="mt-4 space-y-4">
        {questions.map((q, qi) => {
          const choices = pickLocaleChoices(q.choices, locale);
          return (
            <div key={q.id} className="card p-4">
              <p className="text-sm font-medium">
                <span className="mr-1.5 font-mono text-xs text-muted">{qi + 1}.</span>
                {pickLocale(q.question, locale)}
              </p>
              <div className="mt-3 space-y-2">
                {choices.map((choice, ci) => (
                  <button
                    key={ci}
                    onClick={() =>
                      setAnswers((prev) => prev.map((a, i) => (i === qi ? ci : a)))
                    }
                    className={`block w-full rounded-lg border px-3 py-2 text-left text-sm transition ${
                      answers[qi] === ci
                        ? "border-accent bg-accent/10 text-accent"
                        : "border-border bg-surface-2/50 hover:border-border-strong hover:bg-surface-2"
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
        className="btn-primary mt-6 w-full rounded-lg py-2.5 text-sm disabled:cursor-not-allowed disabled:opacity-40"
      >
        {isPending ? t("checking") : t("submit")}
      </button>

      {result && (
        <div
          className={`card mt-3 p-3 text-center text-sm font-semibold ${
            result.passed ? "border-accent/40 bg-accent/5 text-accent" : "border-danger/40 bg-danger/5 text-danger"
          }`}
        >
          {result.passed
            ? t("passed", { correct: result.correctCount, total: result.total })
            : t("failed", { correct: result.correctCount, total: result.total })}
        </div>
      )}
    </div>
  );
}
