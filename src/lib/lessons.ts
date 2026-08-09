import type { Lesson, Profile } from "@/lib/supabase/types";

export type LessonAccess = "completed" | "available" | "locked" | "paywall";

export type LessonWithAccess = Lesson & { access: LessonAccess };

/**
 * Lessons unlock strictly in order. A lesson only becomes reachable once the
 * previous lesson in the same course is completed — subscription status
 * never lets anyone skip ahead, it only decides whether a *reachable* lesson
 * requires payment (`paywall`) or not.
 *
 * Admins bypass both checks entirely (never locked, never paywalled) so
 * they can click through the real student-facing lesson/practice/quiz
 * experience for any lesson to review content, without completing every
 * prerequisite first. This never affects non-admin students.
 */
export function computeLessonAccess(
  lessons: Lesson[],
  completedLessonIds: Set<string>,
  hasPremiumAccess: boolean,
  isAdmin: boolean = false
): LessonWithAccess[] {
  const sorted = [...lessons].sort((a, b) => a.sort_order - b.sort_order);
  let previousCompleted = true;

  return sorted.map((lesson) => {
    const isCompleted = completedLessonIds.has(lesson.id);
    let access: LessonAccess;

    if (isCompleted) {
      access = "completed";
    } else if (isAdmin) {
      access = "available";
    } else if (!previousCompleted) {
      access = "locked";
    } else if (!lesson.is_free && !hasPremiumAccess) {
      access = "paywall";
    } else {
      access = "available";
    }

    previousCompleted = isCompleted;
    return { ...lesson, access };
  });
}

export type CoursePart = "beginner" | "intermediate" | "professional";

// Anchored to stable lesson slugs, not raw sort_order numbers — a future
// content insertion that shifts every later sort_order won't silently move
// these boundaries to the wrong lesson. Only Frontend and Backend have
// enough range to meaningfully split into three; Foundation and Tools stay
// as flat lists (groupLessonsByPart returns null for them).
const PART_BOUNDARIES: Record<string, { part: CoursePart; startsAt: string }[]> = {
  frontend: [
    { part: "beginner", startsAt: "html-hello-world" },
    { part: "intermediate", startsAt: "js-introduction" },
    // Git/GitHub lessons that used to live here moved to the Tools course
    // (see db/foundation_and_tools.sql) — TypeScript is now the first
    // "professional" lesson that actually stayed in Frontend.
    { part: "professional", startsAt: "ts-what-is-typescript" },
  ],
  backend: [
    { part: "beginner", startsAt: "what-happens-when-you-open-a-website" },
    { part: "intermediate", startsAt: "backend-database-tables" },
    { part: "professional", startsAt: "backend-express-middleware" },
  ],
};

export function groupLessonsByPart<T extends { slug: string; sort_order: number }>(
  courseSlug: string,
  lessons: T[]
): { part: CoursePart; lessons: T[] }[] | null {
  const boundaries = PART_BOUNDARIES[courseSlug];
  if (!boundaries) return null;

  const resolved = boundaries.map((b) => ({
    part: b.part,
    sort: lessons.find((l) => l.slug === b.startsAt)?.sort_order ?? -Infinity,
  }));
  const groups: { part: CoursePart; lessons: T[] }[] = resolved.map((r) => ({ part: r.part, lessons: [] }));

  for (const lesson of lessons) {
    let idx = 0;
    for (let i = 0; i < resolved.length; i++) {
      if (lesson.sort_order >= resolved[i].sort) idx = i;
    }
    groups[idx].lessons.push(lesson);
  }
  return groups.filter((g) => g.lessons.length > 0);
}

export function hasPremiumAccess(profile: Pick<Profile, "account_type" | "student_verified_until"> | null): boolean {
  if (!profile) return false;
  if (profile.account_type === "premium") return true;
  if (profile.account_type === "student" && profile.student_verified_until) {
    return new Date(profile.student_verified_until) > new Date();
  }
  return false;
}
