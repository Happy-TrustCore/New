"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "next-intl";
import { askCodeBuddy } from "@/lib/actions/mentor";
import { startCheckout } from "@/lib/actions/billing";

export function CodeBuddyPanel({
  lessonId,
  code,
  isPremium,
}: {
  lessonId: string;
  code: string;
  isPremium: boolean;
}) {
  const t = useTranslations("learn.mentor");
  const [isPending, startTransition] = useTransition();
  const [open, setOpen] = useState(false);
  const [question, setQuestion] = useState("");
  const [reply, setReply] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  function handleAsk() {
    setError(null);
    startTransition(async () => {
      const result = await askCodeBuddy(lessonId, question, code);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setReply(result.reply);
      setQuestion("");
    });
  }

  if (!isPremium) {
    return (
      <div className="shrink-0 border-t border-black/40 bg-[#252526] p-3">
        <div className="flex items-center justify-between gap-3 text-xs text-muted">
          <span>🤖 {t("upsell")}</span>
          <form action={startCheckout}>
            <button type="submit" className="shrink-0 font-semibold text-accent-3 hover:underline">
              {t("upgrade")}
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="shrink-0 border-t border-black/40 bg-[#252526]">
      <button
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center justify-between px-3 py-2.5 text-xs font-semibold text-accent-3 transition hover:bg-white/5"
      >
        <span>🤖 {t("title")}</span>
        <span className={`inline-block transition-transform ${open ? "rotate-180" : ""}`}>▲</span>
      </button>
      {open && (
        <div className="px-3 pb-3">
          {reply && (
            <div className="mb-2 rounded-lg border border-accent-3/30 bg-accent-3/5 p-3 text-sm text-foreground">
              {reply}
            </div>
          )}
          <textarea
            value={question}
            onChange={(e) => setQuestion(e.target.value)}
            placeholder={t("placeholder")}
            rows={2}
            className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm outline-none focus:border-accent-3"
          />
          <button
            onClick={handleAsk}
            disabled={isPending}
            className="mt-2 w-full rounded-lg border border-accent-3/60 py-2 text-sm font-semibold text-accent-3 transition hover:bg-accent-3/10 disabled:opacity-50"
          >
            {isPending ? t("thinking") : t("ask")}
          </button>
          {error && <p className="mt-2 text-xs text-danger">{error}</p>}
        </div>
      )}
    </div>
  );
}
