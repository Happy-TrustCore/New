import type { Lesson, Profile } from "@/lib/supabase/types";

export type LessonAccess = "completed" | "available" | "locked" | "paywall";

export type LessonWithAccess = Lesson & { access: LessonAccess };

/**
 * Lessons unlock strictly in order. A lesson only becomes reachable once the
 * previous lesson in the same course is completed — subscription status
 * never lets anyone skip ahead, it only decides whether a *reachable* lesson
 * requires payment (`paywall`) or not.
 */
export function computeLessonAccess(
  lessons: Lesson[],
  completedLessonIds: Set<string>,
  hasPremiumAccess: boolean
): LessonWithAccess[] {
  const sorted = [...lessons].sort((a, b) => a.sort_order - b.sort_order);
  let previousCompleted = true;

  return sorted.map((lesson) => {
    const isCompleted = completedLessonIds.has(lesson.id);
    let access: LessonAccess;

    if (isCompleted) {
      access = "completed";
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

export function hasPremiumAccess(profile: Pick<Profile, "account_type" | "student_verified_until"> | null): boolean {
  if (!profile) return false;
  if (profile.account_type === "premium") return true;
  if (profile.account_type === "student" && profile.student_verified_until) {
    return new Date(profile.student_verified_until) > new Date();
  }
  return false;
}
