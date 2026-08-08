"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "next-intl";
import { useRouter } from "@/i18n/navigation";
import { submitInterest } from "@/lib/actions/marketplace";

export function InterestButton({
  projectId,
  alreadyInterested,
}: {
  projectId: string;
  alreadyInterested: boolean;
}) {
  const router = useRouter();
  const t = useTranslations("marketplace");
  const [isPending, startTransition] = useTransition();
  const [open, setOpen] = useState(false);
  const [message, setMessage] = useState("");
  const [state, setState] = useState<"idle" | "done" | "error">(
    alreadyInterested ? "done" : "idle"
  );

  function handleSubmit() {
    startTransition(async () => {
      const result = await submitInterest(projectId, message);
      if (!result.ok) {
        setState("error");
        return;
      }
      setState("done");
      setOpen(false);
      router.refresh();
    });
  }

  if (state === "done") {
    return <p className="text-sm font-semibold text-accent">✓ {t("interested")}</p>;
  }

  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        className="btn-primary rounded-lg px-4 py-2 text-sm"
      >
        {t("expressInterest")}
      </button>
    );
  }

  return (
    <div className="w-full">
      <textarea
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        placeholder={t("messagePlaceholder")}
        rows={3}
        className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm outline-none focus:border-accent"
      />
      <div className="mt-2 flex gap-2">
        <button
          onClick={handleSubmit}
          disabled={isPending}
          className="btn-primary rounded-lg px-4 py-2 text-sm disabled:opacity-60"
        >
          {isPending ? t("sending") : t("send")}
        </button>
        <button
          onClick={() => setOpen(false)}
          className="rounded-lg border border-border px-4 py-2 text-sm text-muted hover:bg-surface-2"
        >
          {t("cancel")}
        </button>
      </div>
      {state === "error" && <p className="mt-2 text-xs text-danger">{t("error")}</p>}
    </div>
  );
}
