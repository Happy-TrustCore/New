"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireReachableLesson, finalizeIfReady } from "@/lib/lesson-server";

export type SubmitPracticeResult = { ok: true } | { ok: false; error: string };

export async function submitPractice(lessonId: string): Promise<SubmitPracticeResult> {
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
      practice_passed: true,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id,lesson_id" }
  );
  if (error) return { ok: false, error: error.message };

  await finalizeIfReady(supabase, user.id, lessonId);
  revalidatePath("/dashboard");
  revalidatePath("/learn", "layout");
  return { ok: true };
}
