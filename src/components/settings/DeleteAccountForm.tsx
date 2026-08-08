"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { deleteAccount } from "@/lib/actions/account";

const CONFIRM_WORD = "DELETE";

export function DeleteAccountForm() {
  const t = useTranslations("settings.danger");
  const [confirmText, setConfirmText] = useState("");

  return (
    <form action={deleteAccount} className="card mt-6 border-danger/40 p-6">
      <h2 className="text-sm font-semibold text-danger">{t("title")}</h2>
      <p className="mt-2 text-sm text-muted">{t("body")}</p>
      <label className="mt-4 block">
        <span className="text-sm text-muted">{t("confirmLabel", { word: CONFIRM_WORD })}</span>
        <input
          value={confirmText}
          onChange={(e) => setConfirmText(e.target.value)}
          placeholder={CONFIRM_WORD}
          className="mt-1 w-full rounded-lg border border-danger/40 bg-surface px-3 py-2 outline-none focus:border-danger"
        />
      </label>
      <button
        type="submit"
        disabled={confirmText !== CONFIRM_WORD}
        className="mt-4 rounded-lg border border-danger/60 px-4 py-2 text-sm font-semibold text-danger transition hover:bg-danger/10 disabled:cursor-not-allowed disabled:opacity-40"
      >
        {t("submit")}
      </button>
    </form>
  );
}
