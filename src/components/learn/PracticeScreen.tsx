"use client";

import { useTranslations, useLocale } from "next-intl";
import { Link } from "@/i18n/navigation";
import { CodeWorkspace } from "./CodeWorkspace";
import { startCheckout } from "@/lib/actions/billing";
import { pickLocale } from "@/lib/i18n-content";
import type { LocalizedText, StarterCode } from "@/lib/supabase/types";

export function PracticeScreen({
  lessonTitle,
  taskText,
  paywalled,
  lessonId,
  starterCode,
  practicePassed,
  hasAssignment,
  assignmentPassed,
  isPremium,
  hasQuiz,
  nextLessonSlug,
  onBackToLesson,
  onContinueToQuiz,
}: {
  lessonTitle: LocalizedText;
  taskText: LocalizedText | null;
  paywalled: boolean;
  lessonId: string;
  starterCode: StarterCode | null;
  practicePassed: boolean;
  hasAssignment: boolean;
  assignmentPassed: boolean;
  isPremium: boolean;
  hasQuiz: boolean;
  nextLessonSlug: string | null;
  onBackToLesson: () => void;
  onContinueToQuiz: () => void;
}) {
  const t = useTranslations("learn.practiceScreen");
  const locale = useLocale();
  const readyToContinue = practicePassed && (!hasAssignment || assignmentPassed);
  const lessonDoneWithoutQuiz = !hasQuiz && readyToContinue;

  return (
    <div className="animate-float-in flex h-full flex-col overflow-hidden">
      <div className="glass flex shrink-0 items-center justify-between px-4 py-2.5">
        <button onClick={onBackToLesson} className="text-sm text-muted transition hover:text-foreground">
          &larr; {t("backToLesson")}
        </button>
        {hasQuiz && (
          <button
            onClick={onContinueToQuiz}
            disabled={!readyToContinue}
            className="btn-primary rounded-lg px-4 py-1.5 text-sm disabled:cursor-not-allowed disabled:opacity-40"
          >
            {t("continueToQuiz")} &rarr;
          </button>
        )}
      </div>

      {paywalled ? (
        <div className="flex flex-1 flex-col items-center justify-center gap-3 p-8 text-center">
          <p className="text-sm text-muted">{t("paywall")}</p>
          <form action={startCheckout}>
            <button type="submit" className="btn-primary rounded-lg px-4 py-1.5 text-sm">
              {t("upgrade")}
            </button>
          </form>
        </div>
      ) : (
        <>
          {lessonDoneWithoutQuiz && (
            <div className="glow-accent card m-4 flex flex-wrap items-center justify-between gap-3 p-4">
              <p className="flex items-center gap-2 text-sm font-semibold text-accent">
                🎉 {t("lessonComplete")}
              </p>
              {nextLessonSlug ? (
                <Link href={`/learn/${nextLessonSlug}`} className="btn-primary rounded-lg px-4 py-1.5 text-sm">
                  {t("nextLesson")} &rarr;
                </Link>
              ) : (
                <Link href="/dashboard" className="btn-primary rounded-lg px-4 py-1.5 text-sm">
                  {t("backToDashboard")}
                </Link>
              )}
            </div>
          )}
          <div className="shrink-0 border-b border-border bg-surface p-6">
            <div className="flex items-center gap-2">
              <span className="pill px-3 py-1 text-xs font-mono text-accent-3">
                🎯 {t("whatYoureDoing")}
              </span>
              <span className="pill px-3 py-1 text-xs font-mono text-muted">{t("pacingHint")}</span>
            </div>
            <h2 className="mt-2 text-lg font-semibold">{pickLocale(lessonTitle, locale)}</h2>
            {taskText && (
              <p className="mt-2 max-w-2xl whitespace-pre-line text-sm leading-relaxed text-muted">
                {pickLocale(taskText, locale)}
              </p>
            )}
          </div>
          <div className="min-h-0 flex-1">
            <CodeWorkspace
              lessonId={lessonId}
              starterCode={starterCode}
              practicePassed={practicePassed}
              hasAssignment={hasAssignment}
              assignmentPassed={assignmentPassed}
              isPremium={isPremium}
            />
          </div>
        </>
      )}
    </div>
  );
}
