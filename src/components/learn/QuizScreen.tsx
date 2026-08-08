"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { QuizPanel } from "./QuizPanel";
import type { LocalizedChoices, LocalizedText } from "@/lib/supabase/types";

type QuizQuestionPublic = {
  id: string;
  question: LocalizedText;
  choices: LocalizedChoices;
};

export function QuizScreen({
  lessonId,
  questions,
  alreadyPassed,
  nextLessonSlug,
  onBackToPractice,
}: {
  lessonId: string;
  questions: QuizQuestionPublic[];
  alreadyPassed: boolean;
  nextLessonSlug: string | null;
  onBackToPractice: () => void;
}) {
  const t = useTranslations("learn.quizScreen");
  const [justPassed, setJustPassed] = useState(false);
  const showComplete = alreadyPassed || justPassed;

  return (
    <div className="animate-float-in flex h-full flex-col overflow-y-auto">
      <div className="flex shrink-0 items-center border-b border-border bg-surface px-4 py-2.5">
        <button onClick={onBackToPractice} className="text-sm text-muted hover:text-foreground">
          &larr; {t("backToPractice")}
        </button>
      </div>
      <div className="mx-auto w-full max-w-2xl flex-1 p-6">
        {showComplete && (
          <div className="glow-accent card mb-6 flex flex-col items-center gap-2 p-6 text-center">
            <span className="text-3xl">🎉</span>
            <p className="text-lg font-semibold text-accent">{t("lessonComplete")}</p>
            {nextLessonSlug ? (
              <Link
                href={`/learn/${nextLessonSlug}`}
                className="btn-primary mt-2 rounded-lg px-5 py-2 text-sm"
              >
                {t("nextLesson")} &rarr;
              </Link>
            ) : (
              <Link href="/dashboard" className="btn-primary mt-2 rounded-lg px-5 py-2 text-sm">
                {t("backToDashboard")}
              </Link>
            )}
          </div>
        )}
        <QuizPanel
          lessonId={lessonId}
          questions={questions}
          alreadyPassed={alreadyPassed}
          onPassed={() => setJustPassed(true)}
        />
      </div>
    </div>
  );
}
