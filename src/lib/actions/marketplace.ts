"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { hasPremiumAccess } from "@/lib/lessons";

export type SubmitInterestResult = { ok: true } | { ok: false; error: string };

export async function submitInterest(
  realProjectId: string,
  message: string
): Promise<SubmitInterestResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "You need to be signed in." };

  // Defense in depth: the UI already hides this behind Pro access, but
  // re-check server-side in case of a forged request.
  const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).single();
  if (!hasPremiumAccess(profile)) {
    return { ok: false, error: "This requires CodePath Pro." };
  }

  const { data: project } = await supabase
    .from("real_projects")
    .select("status")
    .eq("id", realProjectId)
    .single();
  if (!project || project.status !== "open") {
    return { ok: false, error: "This project is no longer open." };
  }

  const { error } = await supabase.from("project_interests").upsert(
    {
      real_project_id: realProjectId,
      user_id: user.id,
      message: message.trim() || null,
    },
    { onConflict: "real_project_id,user_id" }
  );
  if (error) return { ok: false, error: error.message };

  revalidatePath("/marketplace");
  return { ok: true };
}
