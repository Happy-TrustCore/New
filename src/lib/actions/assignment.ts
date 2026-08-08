"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireReachableLesson, finalizeIfReady } from "@/lib/lesson-server";
import type { StarterCode } from "@/lib/supabase/types";

export type SubmitAssignmentResult = { ok: true } | { ok: false; error: string };

export async function submitAssignment(
  lessonId: string,
  title: string,
  code: StarterCode
): Promise<SubmitAssignmentResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "You need to be signed in." };

  const check = await requireReachableLesson(supabase, user.id, lessonId);
  if (!check.ok) return { ok: false, error: check.error };

  const trimmedTitle = title.trim();
  if (!trimmedTitle) return { ok: false, error: "Give your project a title." };

  const { error: projectError } = await supabase.from("projects").insert({
    user_id: user.id,
    lesson_id: lessonId,
    title: trimmedTitle,
    code,
  });
  if (projectError) return { ok: false, error: projectError.message };

  const { error: progressError } = await supabase.from("lesson_progress").upsert(
    {
      user_id: user.id,
      lesson_id: lessonId,
      assignment_passed: true,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id,lesson_id" }
  );
  if (progressError) return { ok: false, error: progressError.message };

  await finalizeIfReady(supabase, user.id, lessonId);
  revalidatePath("/dashboard");
  revalidatePath("/learn", "layout");
  return { ok: true };
}
