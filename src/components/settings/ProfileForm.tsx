"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "next-intl";
import { updateProfile } from "@/lib/actions/account";

export function ProfileForm({ currentName }: { currentName: string }) {
  const t = useTranslations("settings.profile");
  const [name, setName] = useState(currentName);
  const [isPending, startTransition] = useTransition();
  const [state, setState] = useState<"idle" | "done" | "error">("idle");
  const [error, setError] = useState("");

  function handleSubmit(formData: FormData) {
    startTransition(async () => {
      const result = await updateProfile(formData);
      if (!result.ok) {
        setError(result.error);
        setState("error");
        return;
      }
      setState("done");
    });
  }

  return (
    <form action={handleSubmit} className="card p-6">
      <h2 className="text-sm font-semibold">{t("title")}</h2>
      <label className="mt-4 block">
        <span className="text-sm text-muted">{t("name")}</span>
        <input
          name="name"
          value={name}
          onChange={(e) => {
            setName(e.target.value);
            setState("idle");
          }}
          required
          className="mt-1 w-full rounded-lg border border-border bg-surface-2/60 px-3 py-2 outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20"
        />
      </label>
      <button
        type="submit"
        disabled={isPending}
        className="btn-primary mt-4 rounded-lg px-4 py-2 text-sm disabled:opacity-60"
      >
        {isPending ? t("saving") : t("save")}
      </button>
      {state === "done" && <p className="mt-2 text-xs text-accent">✓ {t("saved")}</p>}
      {state === "error" && <p className="mt-2 text-xs text-danger">{error}</p>}
    </form>
  );
}
