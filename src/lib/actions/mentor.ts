"use server";

import { getLocale } from "next-intl/server";
import { createClient } from "@/lib/supabase/server";
import { hasPremiumAccess } from "@/lib/lessons";
import { pickLocale } from "@/lib/i18n-content";
import type { Locale } from "@/i18n/routing";

export type AskMentorResult = { ok: true; reply: string } | { ok: false; error: string };

const SYSTEM_PROMPT_EN = `You are CodeBuddy, a friendly coding mentor for beginner programming students on CodePath Academy.
Rules:
- NEVER write the full solution or working code for the student. Give hints, ask guiding questions, and point out what to look at instead.
- Keep responses short (3-6 sentences), encouraging, and beginner-friendly.
- If reviewing code, point out one or two specific, concrete things to improve rather than an exhaustive list.`;

const SYSTEM_PROMPT_DE = `Du bist CodeBuddy, ein freundlicher Coding-Mentor für Programmier-Anfänger bei CodePath Academy.
Regeln:
- Schreibe NIEMALS die vollständige Lösung oder funktionierenden Code für den Studenten. Gib stattdessen Hinweise, stelle Leitfragen und zeige, worauf zu achten ist.
- Halte Antworten kurz (3-6 Sätze), ermutigend und anfängerfreundlich.
- Wenn du Code überprüfst, weise auf ein oder zwei konkrete Verbesserungen hin, keine erschöpfende Liste.
- Antworte auf Deutsch.`;

export async function askCodeBuddy(
  lessonId: string,
  question: string,
  code: string
): Promise<AskMentorResult> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return { ok: false, error: "The AI mentor isn't configured yet." };
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "You need to be signed in." };

  const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).single();
  if (!hasPremiumAccess(profile)) {
    return { ok: false, error: "This requires CodePath Pro." };
  }

  const { data: lesson } = await supabase.from("lessons").select("*").eq("id", lessonId).single();
  if (!lesson) return { ok: false, error: "Lesson not found." };

  const locale = (await getLocale()) as Locale;
  const lessonTitle = pickLocale(lesson.title, locale);
  const systemPrompt = locale === "de" ? SYSTEM_PROMPT_DE : SYSTEM_PROMPT_EN;

  const trimmedCode = code.slice(0, 4000);
  const trimmedQuestion = question.trim().slice(0, 500);
  const userMessage = `Lesson: "${lessonTitle}"

Student's current code:
${trimmedCode || "(no code yet)"}

Student's question: ${
    trimmedQuestion || "(no specific question — review my code and suggest what to try next)"
  }`;

  const model = process.env.GEMINI_MODEL || "gemini-2.0-flash";

  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemPrompt }] },
          contents: [{ role: "user", parts: [{ text: userMessage }] }],
          generationConfig: { maxOutputTokens: 300, temperature: 0.7 },
        }),
      }
    );

    if (!response.ok) {
      return { ok: false, error: "CodeBuddy is unavailable right now — try again later." };
    }

    const data = await response.json();
    const reply: string | undefined = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!reply) {
      return { ok: false, error: "CodeBuddy couldn't come up with a reply — try rephrasing." };
    }

    return { ok: true, reply: reply.trim() };
  } catch {
    return { ok: false, error: "CodeBuddy is unavailable right now — try again later." };
  }
}
