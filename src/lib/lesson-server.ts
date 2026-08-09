// Server-only helpers shared by the practice/quiz Server Actions.
// Deliberately NOT a "use server" module itself — only the action entry
// points in src/lib/actions/ are exposed as callable actions; splitting each
// action into its own file avoids ambiguity in the Server Action reference
// each exported function resolves to.

import { createClient } from "@/lib/supabase/server";
import { computeLessonAccess, hasPremiumAccess } from "@/lib/lessons";
import { isCourseFullyCompleted } from "@/lib/certificates";
import { computeStreakUpdate } from "@/lib/streaks";
import type { Lesson } from "@/lib/supabase/types";

export const XP_PER_LESSON = 10;

export type Client = Awaited<ReturnType<typeof createClient>>;

export type ReachableLessonCheck =
  | { ok: true; lesson: Lesson }
  | { ok: false; error: string };

export async function requireReachableLesson(
  supabase: Client,
  userId: string,
  lessonId: string
): Promise<ReachableLessonCheck> {
  const { data: lesson } = await supabase.from("lessons").select("*").eq("id", lessonId).single();
  if (!lesson) {
    return { ok: false, error: "Lesson not found." };
  }

  const [{ data: courseLessons }, { data: completedRows }, { data: profile }] = await Promise.all([
    supabase.from("lessons").select("*").eq("course_id", lesson.course_id),
    supabase
      .from("lesson_progress")
      .select("lesson_id")
      .eq("user_id", userId)
      .eq("status", "completed"),
    supabase.from("profiles").select("*").eq("id", userId).single(),
  ]);

  const completedIds = new Set((completedRows ?? []).map((row) => row.lesson_id));
  const withAccess = computeLessonAccess(
    courseLessons ?? [],
    completedIds,
    hasPremiumAccess(profile),
    profile?.is_admin ?? false
  );
  const target = withAccess.find((l) => l.id === lessonId);

  // Defense in depth: the UI already prevents this call from firing on a
  // locked/paywalled lesson, but re-check server-side in case of a forged request.
  if (!target || (target.access !== "available" && target.access !== "completed")) {
    return { ok: false, error: "This lesson isn't unlocked yet." };
  }

  return { ok: true, lesson };
}

export async function finalizeIfReady(supabase: Client, userId: string, lessonId: string) {
  const [{ data: lesson }, { data: progress }, { count: quizCount }] = await Promise.all([
    supabase.from("lessons").select("*").eq("id", lessonId).single(),
    supabase
      .from("lesson_progress")
      .select("*")
      .eq("user_id", userId)
      .eq("lesson_id", lessonId)
      .maybeSingle(),
    supabase
      .from("quiz_questions")
      .select("id", { count: "exact", head: true })
      .eq("lesson_id", lessonId),
  ]);

  if (!lesson || !progress || progress.status === "completed") return;

  const practiceRequired = lesson.starter_code !== null;
  const practiceOk = !practiceRequired || progress.practice_passed;
  const quizRequired = (quizCount ?? 0) > 0;
  const quizOk = !quizRequired || progress.quiz_passed;
  const assignmentOk = !lesson.has_assignment || progress.assignment_passed;

  if (!practiceOk || !quizOk || !assignmentOk) return;

  await supabase
    .from("lesson_progress")
    .update({ status: "completed", completed_at: new Date().toISOString() })
    .eq("user_id", userId)
    .eq("lesson_id", lessonId);

  const { data: profile } = await supabase
    .from("profiles")
    .select("xp, name, current_streak, longest_streak, last_activity_date")
    .eq("id", userId)
    .single();
  if (profile) {
    const newXp = profile.xp + XP_PER_LESSON;
    const streak = computeStreakUpdate(
      profile.last_activity_date,
      profile.current_streak,
      profile.longest_streak
    );
    await supabase
      .from("profiles")
      .update({ xp: newXp, level: Math.floor(newXp / 100) + 1, ...streak })
      .eq("id", userId);
  }

  await maybeIssueCertificate(supabase, userId, lesson.course_id, profile?.name);
}

async function maybeIssueCertificate(
  supabase: Client,
  userId: string,
  courseId: string,
  studentName: string | undefined
) {
  if (!studentName) return;

  const [{ data: courseLessons }, { data: completedRows }] = await Promise.all([
    supabase.from("lessons").select("id").eq("course_id", courseId),
    supabase
      .from("lesson_progress")
      .select("lesson_id")
      .eq("user_id", userId)
      .eq("status", "completed"),
  ]);

  const completedIds = new Set((completedRows ?? []).map((row) => row.lesson_id));
  if (!isCourseFullyCompleted(courseLessons ?? [], completedIds)) return;

  await supabase
    .from("certificates")
    .upsert(
      { user_id: userId, course_id: courseId, student_name: studentName },
      { onConflict: "user_id,course_id", ignoreDuplicates: true }
    );
}
