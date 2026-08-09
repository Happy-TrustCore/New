"use client";

import { useState } from "react";
import { useLocale, useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import type { LessonWithAccess } from "@/lib/lessons";
import { pickLocale } from "@/lib/i18n-content";

export function LessonSidebar({
  courseTitle,
  lessons,
  currentLessonId,
}: {
  courseTitle: string;
  lessons: LessonWithAccess[];
  currentLessonId: string;
}) {
  const locale = useLocale();
  const t = useTranslations("learn.sidebar");
  const [mobileOpen, setMobileOpen] = useState(false);
  const currentIndex = lessons.findIndex((l) => l.id === currentLessonId);

  const navList = (
    <ul className="mt-3 space-y-1">
      {lessons.map((lesson, i) => {
        const isCurrent = lesson.id === currentLessonId;
        const title = pickLocale(lesson.title, locale);
        const icon =
          lesson.access === "completed"
            ? "✓"
            : lesson.access === "locked" || lesson.access === "paywall"
            ? "🔒"
            : "▶";

        const rowClasses = `flex items-center gap-2 rounded-lg px-3 py-2 text-sm ${
          isCurrent
            ? "bg-accent/10 text-accent font-semibold"
            : lesson.access === "completed"
            ? "text-foreground hover:bg-surface-2"
            : "text-muted"
        }`;

        if (lesson.access === "locked") {
          return (
            <li key={lesson.id} className={`${rowClasses} cursor-not-allowed`}>
              <span className="w-4 shrink-0">{icon}</span>
              <span className="truncate">
                {i + 1}. {title}
              </span>
            </li>
          );
        }

        if (lesson.access === "paywall") {
          return (
            <li key={lesson.id}>
              <Link href="/#pricing" className={`${rowClasses} hover:bg-surface-2`}>
                <span className="w-4 shrink-0">{icon}</span>
                <span className="truncate">
                  {i + 1}. {title}
                </span>
                <span className="ml-auto shrink-0 text-[10px] text-accent">{t("pro")}</span>
              </Link>
            </li>
          );
        }

        return (
          <li key={lesson.id}>
            <Link
              href={`/learn/${lesson.slug}`}
              onClick={() => setMobileOpen(false)}
              className={rowClasses}
            >
              <span className="w-4 shrink-0">{icon}</span>
              <span className="truncate">
                {i + 1}. {title}
              </span>
            </Link>
          </li>
        );
      })}
    </ul>
  );

  return (
    <>
      {/* mobile: slim toggle bar instead of the full sidebar taking up screen width */}
      <button
        onClick={() => setMobileOpen(true)}
        className="flex w-full items-center gap-2 border-b border-border bg-surface/60 px-4 py-2.5 text-sm font-semibold sm:hidden"
      >
        <span>☰</span>
        <span className="truncate">
          {courseTitle}
          {currentIndex >= 0 && (
            <span className="ml-1 font-normal text-muted">
              — {t("lessonOf", { current: currentIndex + 1, total: lessons.length })}
            </span>
          )}
        </span>
      </button>

      {/* desktop: sidebar occupies its own grid column as before */}
      <nav className="hidden h-full flex-col overflow-y-auto border-r border-border bg-surface/60 p-4 sm:flex">
        <p className="px-2 text-xs font-semibold uppercase tracking-wide text-muted">{courseTitle}</p>
        {navList}
      </nav>

      {/* mobile: drawer overlay, escapes the grid entirely via fixed positioning */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 flex sm:hidden">
          <div className="absolute inset-0 bg-black/60" onClick={() => setMobileOpen(false)} />
          <div className="relative flex h-full w-72 max-w-[85vw] flex-col overflow-y-auto bg-background p-4 shadow-2xl">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted">{courseTitle}</p>
              <button
                onClick={() => setMobileOpen(false)}
                className="rounded-lg px-2 py-1 text-muted hover:bg-surface-2 hover:text-foreground"
              >
                ✕
              </button>
            </div>
            {navList}
          </div>
        </div>
      )}
    </>
  );
}
