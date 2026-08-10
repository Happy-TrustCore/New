"use client";

import { useState, type FormEvent } from "react";
import { useTranslations } from "next-intl";
import { useRouter } from "@/i18n/navigation";
import { createClient } from "@/lib/supabase/client";

export default function ResetPasswordPage() {
  const t = useTranslations("auth.resetPassword");
  const router = useRouter();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [state, setState] = useState<"idle" | "saving" | "done" | "error">("idle");
  const [error, setError] = useState("");

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();

    if (password.length < 8) {
      setError(t("tooShort"));
      setState("error");
      return;
    }
    if (password !== confirm) {
      setError(t("mismatch"));
      setState("error");
      return;
    }

    setState("saving");
    const supabase = createClient();
    const { error: updateError } = await supabase.auth.updateUser({ password });
    if (updateError) {
      setError(updateError.message);
      setState("error");
      return;
    }

    setState("done");
    setTimeout(() => router.push("/dashboard"), 1500);
  }

  return (
    <main className="flex flex-1 items-center justify-center px-6 py-16">
      <div className="w-full max-w-sm">
        <div className="card animate-float-in p-7">
          <h1 className="text-2xl font-bold">
            <span className="text-gradient">{t("title")}</span>
          </h1>
          <p className="mt-1 text-sm text-muted">{t("subtitle")}</p>

          {state === "done" ? (
            <p className="mt-6 rounded-lg border border-accent/40 bg-accent/10 px-4 py-3 text-sm text-accent">
              {t("success")}
            </p>
          ) : (
            <form onSubmit={handleSubmit} className="mt-6 space-y-4">
              <div>
                <label htmlFor="password" className="text-sm text-muted">
                  {t("newPassword")}
                </label>
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="mt-1 w-full rounded-lg border border-border bg-surface-2/60 px-3 py-2 outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20"
                />
              </div>
              <div>
                <label htmlFor="confirm" className="text-sm text-muted">
                  {t("confirmPassword")}
                </label>
                <input
                  id="confirm"
                  type="password"
                  value={confirm}
                  onChange={(e) => setConfirm(e.target.value)}
                  required
                  className="mt-1 w-full rounded-lg border border-border bg-surface-2/60 px-3 py-2 outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/20"
                />
              </div>
              {error && <p className="text-xs text-danger">{error}</p>}
              <button
                type="submit"
                disabled={state === "saving"}
                className="btn-primary w-full rounded-lg py-2.5 disabled:opacity-60"
              >
                {state === "saving" ? t("saving") : t("submit")}
              </button>
            </form>
          )}
        </div>
      </div>
    </main>
  );
}
