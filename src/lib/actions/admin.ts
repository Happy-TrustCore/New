"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { AccountType, Difficulty, LessonContentBlock, StarterCode } from "@/lib/supabase/types";

async function requireAdmin() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .single();
  if (!profile?.is_admin) redirect("/dashboard");

  return supabase;
}

function parseSteps(raw: string): LessonContentBlock[] {
  return raw
    .split(/\n\s*---\s*\n/)
    .map((s) => s.trim())
    .filter(Boolean)
    .map((text, i) => ({ step: i + 1, text }));
}

function parseStarterCode(formData: FormData): StarterCode | null {
  const code: StarterCode = {};
  let any = false;
  if (formData.get("enable_html")) {
    code.html = String(formData.get("code_html") ?? "");
    any = true;
  }
  if (formData.get("enable_css")) {
    code.css = String(formData.get("code_css") ?? "");
    any = true;
  }
  if (formData.get("enable_js")) {
    code.js = String(formData.get("code_js") ?? "");
    any = true;
  }
  return any ? code : null;
}

function lessonFieldsFromForm(formData: FormData) {
  return {
    course_id: String(formData.get("course_id")),
    slug: String(formData.get("slug")).trim(),
    title: String(formData.get("title")).trim(),
    difficulty: String(formData.get("difficulty")) as Difficulty,
    is_free: formData.get("is_free") === "on",
    sort_order: Number(formData.get("sort_order")),
    content: parseSteps(String(formData.get("content") ?? "")),
    starter_code: parseStarterCode(formData),
  };
}

export async function createLesson(formData: FormData) {
  const supabase = await requireAdmin();

  const { error } = await supabase.from("lessons").insert(lessonFieldsFromForm(formData));

  if (error) {
    redirect(`/admin/lessons/new?error=${encodeURIComponent(error.message)}`);
  }

  revalidatePath("/admin/lessons");
  revalidatePath("/learn", "layout");
  redirect("/admin/lessons");
}

export async function updateLesson(lessonId: string, formData: FormData) {
  const supabase = await requireAdmin();

  const { error } = await supabase
    .from("lessons")
    .update(lessonFieldsFromForm(formData))
    .eq("id", lessonId);

  if (error) {
    redirect(`/admin/lessons/${lessonId}?error=${encodeURIComponent(error.message)}`);
  }

  revalidatePath("/admin/lessons");
  revalidatePath("/learn", "layout");
  redirect("/admin/lessons");
}

export async function deleteLesson(lessonId: string) {
  const supabase = await requireAdmin();
  await supabase.from("lessons").delete().eq("id", lessonId);
  revalidatePath("/admin/lessons");
  revalidatePath("/learn", "layout");
  redirect("/admin/lessons");
}

export async function addQuizQuestion(lessonId: string, formData: FormData) {
  const supabase = await requireAdmin();

  const choices = [0, 1, 2, 3]
    .map((i) => String(formData.get(`choice_${i}`) ?? "").trim())
    .filter(Boolean);

  const { count } = await supabase
    .from("quiz_questions")
    .select("id", { count: "exact", head: true })
    .eq("lesson_id", lessonId);

  await supabase.from("quiz_questions").insert({
    lesson_id: lessonId,
    question: String(formData.get("question") ?? "").trim(),
    choices,
    correct_index: Number(formData.get("correct_index")),
    sort_order: (count ?? 0) + 1,
  });

  revalidatePath(`/admin/lessons/${lessonId}`);
  redirect(`/admin/lessons/${lessonId}`);
}

export async function deleteQuizQuestion(lessonId: string, questionId: string) {
  const supabase = await requireAdmin();
  await supabase.from("quiz_questions").delete().eq("id", questionId);
  revalidatePath(`/admin/lessons/${lessonId}`);
  redirect(`/admin/lessons/${lessonId}`);
}

export async function setAccountType(userId: string, accountType: AccountType) {
  const supabase = await requireAdmin();
  await supabase.from("profiles").update({ account_type: accountType }).eq("id", userId);
  await supabase.from("subscriptions").update({ plan: accountType }).eq("user_id", userId);
  revalidatePath("/admin/users");
}
