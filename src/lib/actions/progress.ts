"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireReachableLesson } from "@/lib/lesson-server";

export type MarkContentViewedResult = { ok: true } | { ok: false; error: string };

// Records that the student finished reading a lesson's content steps,
// independent of practice/quiz/assignment — this is what lets "Lesson N"
// show its own checkmark in the sidebar before "Practice N" is even started.
export async function markContentViewed(lessonId: string): Promise<MarkContentViewedResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "You need to be signed in." };

  const check = await requireReachableLesson(supabase, user.id, lessonId);
  if (!check.ok) return { ok: false, error: check.error };

  const { error } = await supabase.from("lesson_progress").upsert(
    {
      user_id: user.id,
      lesson_id: lessonId,
      content_viewed: true,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id,lesson_id" }
  );
  if (error) return { ok: false, error: error.message };

  revalidatePath("/learn", "layout");
  return { ok: true };
}
