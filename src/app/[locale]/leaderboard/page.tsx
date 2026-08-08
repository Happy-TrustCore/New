import { getTranslations } from "next-intl/server";
import { redirect } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";

const MEDAL = ["🥇", "🥈", "🥉"];

export default async function LeaderboardPage({
  params,
}: PageProps<"/[locale]/leaderboard">) {
  const { locale } = (await params) as { locale: Locale };
  const supabase = await createClient();
  const t = await getTranslations("leaderboard");

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return redirect({ href: "/login", locale });

  const { data: entries } = await supabase.rpc("get_leaderboard", { result_limit: 50 });
  const rows = entries ?? [];
  const isRanked = rows.some((row) => row.id === user.id);

  return (
    <div className="mx-auto max-w-2xl px-6 py-10">
      <h1 className="text-2xl font-bold">{t("title")}</h1>
      <p className="mt-1 text-sm text-muted">{t("subtitle")}</p>

      <div className="mt-8 divide-y divide-border overflow-hidden rounded-xl border border-border bg-surface">
        {rows.length === 0 && <p className="px-4 py-6 text-sm text-muted">{t("empty")}</p>}
        {rows.map((row, i) => {
          const isMe = row.id === user.id;
          return (
            <div
              key={row.id}
              className={`flex items-center gap-4 px-4 py-3 ${isMe ? "bg-accent/10" : ""}`}
            >
              <span className="w-8 shrink-0 text-center font-mono text-sm text-muted">
                {MEDAL[i] ?? `#${i + 1}`}
              </span>
              <span className={`flex-1 text-sm ${isMe ? "font-semibold text-accent" : ""}`}>
                {row.name}
                {isMe && <span className="ml-2 text-xs text-muted">{t("you")}</span>}
              </span>
              <span className="font-mono text-sm text-muted">
                {t("levelXp", { level: row.level, xp: row.xp })}
              </span>
            </div>
          );
        })}
      </div>

      {!isRanked && rows.length > 0 && (
        <p className="mt-4 text-center text-sm text-muted">{t("notRanked")}</p>
      )}
    </div>
  );
}
