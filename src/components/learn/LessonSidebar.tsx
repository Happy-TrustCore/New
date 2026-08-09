"use client";

import { useState } from "react";
import { useLocale, useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { groupLessonsByPart, type LessonWithAccess } from "@/lib/lessons";
import { pickLocale } from "@/lib/i18n-content";

export function LessonSidebar({
  courseTitle,
  courseSlug,
  lessons,
  currentLessonId,
  currentMode = "lesson",
  contentViewedIds,
  isAdmin = false,
  courseGroups,
}: {
  courseTitle: string;
  courseSlug: string;
  lessons: LessonWithAccess[];
  currentLessonId: string;
  currentMode?: "lesson" | "practice" | "quiz";
  contentViewedIds: Set<string>;
  isAdmin?: boolean;
  // Admin-only: every track's lessons, grouped, so an admin sees Foundation
  // + Frontend + Backend all in one sidebar instead of only the current
  // track. When present, this replaces the single-track `lessons` list.
  courseGroups?: { slug: string; title: string; lessons: LessonWithAccess[] }[];
}) {
  const locale = useLocale();
  const t = useTranslations("learn.sidebar");
  const [mobileOpen, setMobileOpen] = useState(false);
  const currentIndex = lessons.findIndex((l) => l.id === currentLessonId);

  function rowClasses(isCurrent: boolean, done: boolean) {
    return `flex items-center gap-2 rounded-lg px-3 py-2 text-sm ${
      isCurrent
        ? "bg-accent/10 text-accent font-semibold"
        : done
        ? "text-foreground hover:bg-surface-2"
        : "text-muted"
    }`;
  }

  // `lessonList` here is always the FULL course list (never a pre-sliced
  // part), so numbering stays correct even when part-grouping wraps
  // sub-ranges of it under headers below.
  function renderLessonList(lessonList: LessonWithAccess[], courseSlugForParts?: string) {
    const indexOf = new Map(lessonList.map((l, i) => [l.id, i]));

    function renderRow(lesson: LessonWithAccess) {
      const i = indexOf.get(lesson.id) ?? 0;
      const title = pickLocale(lesson.title, locale);
      const hasPractice = lesson.starter_code !== null;
      const contentViewed = isAdmin || contentViewedIds.has(lesson.id);

      if (lesson.access === "locked") {
        return (
          <li key={lesson.id} className={`${rowClasses(false, false)} cursor-not-allowed`}>
            <span className="w-4 shrink-0">🔒</span>
            <span className="truncate">
              {i + 1}. {title}
            </span>
          </li>
        );
      }

      if (lesson.access === "paywall") {
        return (
          <li key={lesson.id}>
            <Link href="/#pricing" className={`${rowClasses(false, false)} hover:bg-surface-2`}>
              <span className="w-4 shrink-0">🔒</span>
              <span className="truncate">
                {i + 1}. {title}
              </span>
              <span className="ml-auto shrink-0 text-[10px] text-accent">{t("pro")}</span>
            </Link>
          </li>
        );
      }

      const lessonDone = contentViewed || lesson.access === "completed";
      const isLessonRowCurrent = lesson.id === currentLessonId && currentMode === "lesson";
      const isPracticeRowCurrent =
        lesson.id === currentLessonId && (currentMode === "practice" || currentMode === "quiz");
      const practiceDone = lesson.access === "completed";

      return (
        <li key={lesson.id} className="space-y-1">
          <Link
            href={`/learn/${lesson.slug}`}
            onClick={() => setMobileOpen(false)}
            className={rowClasses(isLessonRowCurrent, lessonDone)}
          >
            <span className="w-4 shrink-0">{lessonDone ? "✓" : "▶"}</span>
            <span className="truncate">
              {i + 1}. {title}
            </span>
          </Link>
          {hasPractice &&
            (contentViewed ? (
              <Link
                href={`/learn/${lesson.slug}?start=practice`}
                onClick={() => setMobileOpen(false)}
                className={`${rowClasses(isPracticeRowCurrent, practiceDone)} pl-7`}
              >
                <span className="w-4 shrink-0">{practiceDone ? "✓" : "▶"}</span>
                <span className="truncate">
                  {i + 1}. {t("practice")}
                </span>
              </Link>
            ) : (
              <div className={`${rowClasses(false, false)} cursor-not-allowed pl-7`}>
                <span className="w-4 shrink-0">🔒</span>
                <span className="truncate">
                  {i + 1}. {t("practice")}
                </span>
              </div>
            ))}
        </li>
      );
    }

    const parts = courseSlugForParts ? groupLessonsByPart(courseSlugForParts, lessonList) : null;

    if (parts) {
      return (
        <div className="mt-3 space-y-4">
          {parts.map((group) => (
            <div key={group.part}>
              <p className="px-1 text-[10px] font-semibold uppercase tracking-wide text-accent/70">
                {t(`part.${group.part}`)}
              </p>
              <ul className="mt-1 space-y-1">{group.lessons.map(renderRow)}</ul>
            </div>
          ))}
        </div>
      );
    }

    return <ul className="mt-3 space-y-1">{lessonList.map(renderRow)}</ul>;
  }

  const headerLabel = courseGroups ? t("allTracks") : courseTitle;

  const navList = courseGroups ? (
    <div className="mt-3 space-y-5">
      {courseGroups.map((group) => (
        <div key={group.title}>
          <p className="px-1 text-[11px] font-semibold uppercase tracking-wide text-muted/80">
            {group.title}
          </p>
          {renderLessonList(group.lessons, group.slug)}
        </div>
      ))}
    </div>
  ) : (
    renderLessonList(lessons, courseSlug)
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
          {headerLabel}
          {!courseGroups && currentIndex >= 0 && (
            <span className="ml-1 font-normal text-muted">
              — {t("lessonOf", { current: currentIndex + 1, total: lessons.length })}
            </span>
          )}
        </span>
      </button>

      {/* desktop: sidebar occupies its own grid column as before */}
      <nav className="hidden h-full flex-col overflow-y-auto border-r border-border bg-surface/60 p-4 sm:flex">
        <p className="px-2 text-xs font-semibold uppercase tracking-wide text-muted">{headerLabel}</p>
        {navList}
      </nav>

      {/* mobile: drawer overlay, escapes the grid entirely via fixed positioning */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 flex sm:hidden">
          <div className="absolute inset-0 bg-black/60" onClick={() => setMobileOpen(false)} />
          <div className="relative flex h-full w-72 max-w-[85vw] flex-col overflow-y-auto bg-background p-4 shadow-2xl">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted">{headerLabel}</p>
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
