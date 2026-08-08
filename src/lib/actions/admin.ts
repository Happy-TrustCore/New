"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "@/i18n/navigation";
import { getLocale } from "next-intl/server";
import { createClient } from "@/lib/supabase/server";
import type { AccountType, Difficulty, LessonContentBlock, StarterCode } from "@/lib/supabase/types";

async function requireAdmin() {
  const locale = await getLocale();
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return redirect({ href: "/login", locale });

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .single();
  if (!profile?.is_admin) return redirect({ href: "/dashboard", locale });

  return { supabase, locale };
}

function splitSteps(raw: string): string[] {
  return raw
    .split(/\n\s*---\s*\n/)
    .map((s) => s.trim())
    .filter(Boolean);
}

function parseSteps(rawEn: string, rawDe: string): LessonContentBlock[] {
  const en = splitSteps(rawEn);
  const de = splitSteps(rawDe);
  const count = Math.max(en.length, de.length);
  return Array.from({ length: count }, (_, i) => ({
    step: i + 1,
    text: { en: en[i] ?? "", de: de[i] ?? "" },
  }));
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
  if (formData.get("enable_jsx")) {
    code.jsx = String(formData.get("code_jsx") ?? "");
    any = true;
  }
  return any ? code : null;
}

function lessonFieldsFromForm(formData: FormData) {
  return {
    course_id: String(formData.get("course_id")),
    slug: String(formData.get("slug")).trim(),
    title: {
      en: String(formData.get("title_en") ?? "").trim(),
      de: String(formData.get("title_de") ?? "").trim(),
    },
    difficulty: String(formData.get("difficulty")) as Difficulty,
    is_free: formData.get("is_free") === "on",
    has_assignment: formData.get("has_assignment") === "on",
    sort_order: Number(formData.get("sort_order")),
    content: parseSteps(
      String(formData.get("content_en") ?? ""),
      String(formData.get("content_de") ?? "")
    ),
    starter_code: parseStarterCode(formData),
  };
}

export async function createLesson(formData: FormData) {
  const { supabase, locale } = await requireAdmin();

  const { error } = await supabase.from("lessons").insert(lessonFieldsFromForm(formData));

  if (error) {
    redirect({
      href: `/admin/lessons/new?error=${encodeURIComponent(error.message)}`,
      locale,
    });
  }

  revalidatePath("/admin/lessons");
  revalidatePath("/learn", "layout");
  redirect({ href: "/admin/lessons", locale });
}

export async function updateLesson(lessonId: string, formData: FormData) {
  const { supabase, locale } = await requireAdmin();

  const { error } = await supabase
    .from("lessons")
    .update(lessonFieldsFromForm(formData))
    .eq("id", lessonId);

  if (error) {
    redirect({
      href: `/admin/lessons/${lessonId}?error=${encodeURIComponent(error.message)}`,
      locale,
    });
  }

  revalidatePath("/admin/lessons");
  revalidatePath("/learn", "layout");
  redirect({ href: "/admin/lessons", locale });
}

export async function deleteLesson(lessonId: string) {
  const { supabase, locale } = await requireAdmin();
  await supabase.from("lessons").delete().eq("id", lessonId);
  revalidatePath("/admin/lessons");
  revalidatePath("/learn", "layout");
  redirect({ href: "/admin/lessons", locale });
}

export async function addQuizQuestion(lessonId: string, formData: FormData) {
  const { supabase, locale } = await requireAdmin();

  // English is the authoritative source for which choice slots are "real" —
  // a slot is kept only if its English value is filled in, and the matching
  // German value (even if blank) rides along at the same index so
  // correct_index stays valid for both languages.
  const rawEn = [0, 1, 2, 3].map((i) => String(formData.get(`choice_${i}_en`) ?? "").trim());
  const rawDe = [0, 1, 2, 3].map((i) => String(formData.get(`choice_${i}_de`) ?? "").trim());
  const keepIndices = rawEn.map((v, i) => (v !== "" ? i : -1)).filter((i) => i !== -1);

  const { count } = await supabase
    .from("quiz_questions")
    .select("id", { count: "exact", head: true })
    .eq("lesson_id", lessonId);

  await supabase.from("quiz_questions").insert({
    lesson_id: lessonId,
    question: {
      en: String(formData.get("question_en") ?? "").trim(),
      de: String(formData.get("question_de") ?? "").trim(),
    },
    choices: {
      en: keepIndices.map((i) => rawEn[i]),
      de: keepIndices.map((i) => rawDe[i]),
    },
    correct_index: Number(formData.get("correct_index")),
    sort_order: (count ?? 0) + 1,
  });

  revalidatePath(`/admin/lessons/${lessonId}`);
  redirect({ href: `/admin/lessons/${lessonId}`, locale });
}

export async function deleteQuizQuestion(lessonId: string, questionId: string) {
  const { supabase, locale } = await requireAdmin();
  await supabase.from("quiz_questions").delete().eq("id", questionId);
  revalidatePath(`/admin/lessons/${lessonId}`);
  redirect({ href: `/admin/lessons/${lessonId}`, locale });
}

export async function setAccountType(userId: string, accountType: AccountType) {
  const { supabase } = await requireAdmin();
  await supabase.from("profiles").update({ account_type: accountType }).eq("id", userId);
  await supabase.from("subscriptions").update({ plan: accountType }).eq("user_id", userId);
  revalidatePath("/admin/users");
}
