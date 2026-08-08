import type { Lesson } from "@/lib/supabase/types";

/**
 * A course counts as fully completed once every one of its lessons has a
 * completed lesson_progress row for this user. Courses with zero lessons
 * never count as "completed" — there's nothing to certify.
 */
export function isCourseFullyCompleted(
  courseLessons: Pick<Lesson, "id">[],
  completedLessonIds: Set<string>
): boolean {
  if (courseLessons.length === 0) return false;
  return courseLessons.every((lesson) => completedLessonIds.has(lesson.id));
}
