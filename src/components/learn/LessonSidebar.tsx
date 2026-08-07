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

  return (
    <nav className="flex h-full flex-col overflow-y-auto border-r border-border bg-surface/60 p-4">
      <p className="px-2 text-xs font-semibold uppercase tracking-wide text-muted">
        {courseTitle}
      </p>
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
              <Link href={`/learn/${lesson.slug}`} className={rowClasses}>
                <span className="w-4 shrink-0">{icon}</span>
                <span className="truncate">
                  {i + 1}. {title}
                </span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
