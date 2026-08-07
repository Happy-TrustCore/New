import type { Locale } from "@/i18n/routing";
import type { LocalizedChoices, LocalizedText } from "@/lib/supabase/types";

export function pickLocale(text: LocalizedText | null | undefined, locale: Locale): string {
  if (!text) return "";
  return text[locale] ?? text.en ?? "";
}

export function pickLocaleChoices(
  choices: LocalizedChoices | null | undefined,
  locale: Locale
): string[] {
  if (!choices) return [];
  return choices[locale] ?? choices.en ?? [];
}
