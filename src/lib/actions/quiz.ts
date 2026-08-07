"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireReachableLesson, finalizeIfReady } from "@/lib/lesson-server";

export type SubmitQuizResult =
  | { ok: true; passed: boolean; correctCount: number; total: number }
  | { ok: false; error: string };

export async function submitQuiz(
  lessonId: string,
  answers: number[]
): Promise<SubmitQuizResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "You need to be signed in." };

  const check = await requireReachableLesson(supabase, user.id, lessonId);
  if (!check.ok) return { ok: false, error: check.error };

  const { data: questions } = await supabase
    .from("quiz_questions")
    .select("*")
    .eq("lesson_id", lessonId)
    .order("sort_order");

  if (!questions || questions.length === 0) {
    return { ok: false, error: "This lesson has no quiz." };
  }

  const correctCount = questions.reduce(
    (count, q, i) => count + (answers[i] === q.correct_index ? 1 : 0),
    0
  );
  const passed = correctCount / questions.length >= 0.7;

  const { error } = await supabase.from("lesson_progress").upsert(
    {
      user_id: user.id,
      lesson_id: lessonId,
      quiz_passed: passed,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id,lesson_id" }
  );
  if (error) return { ok: false, error: error.message };

  if (passed) {
    await finalizeIfReady(supabase, user.id, lessonId);
    revalidatePath("/dashboard");
    revalidatePath("/learn", "layout");
  }

  return { ok: true, passed, correctCount, total: questions.length };
}
