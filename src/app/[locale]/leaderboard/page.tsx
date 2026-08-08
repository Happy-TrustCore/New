import { getTranslations } from "next-intl/server";
import { redirect } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";
import type { LeaderboardEntry } from "@/lib/supabase/types";

const PODIUM = [
  { rank: 1, medal: "🥇", order: "sm:order-2", height: "sm:pt-0", ring: "border-accent-warm/60" },
  { rank: 2, medal: "🥈", order: "sm:order-1", height: "sm:pt-6", ring: "border-border-strong" },
  { rank: 3, medal: "🥉", order: "sm:order-3", height: "sm:pt-10", ring: "border-accent-3/40" },
];

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
  const top3 = rows.slice(0, 3);
  const rest = rows.slice(3);
  const isRanked = rows.some((row) => row.id === user.id);

  return (
    <div className="mx-auto max-w-2xl px-6 py-10">
      <h1 className="text-2xl font-bold">{t("title")}</h1>
      <p className="mt-1 text-sm text-muted">{t("subtitle")}</p>

      {rows.length === 0 ? (
        <p className="mt-8 rounded-xl border border-border bg-surface px-4 py-6 text-center text-sm text-muted">
          {t("empty")}
        </p>
      ) : (
        <>
          {top3.length > 0 && (
            <div className="mt-10 flex flex-col items-stretch gap-4 sm:flex-row sm:items-end">
              {top3.map((row, i) => (
                <PodiumCard key={row.id} row={row} spec={PODIUM[i]} isMe={row.id === user.id} t={t} />
              ))}
            </div>
          )}

          {rest.length > 0 && (
            <div className="mt-8 divide-y divide-border overflow-hidden rounded-xl border border-border bg-surface">
              {rest.map((row, i) => {
                const isMe = row.id === user.id;
                return (
                  <div
                    key={row.id}
                    className={`flex items-center gap-4 px-4 py-3 ${isMe ? "bg-accent/10" : ""}`}
                  >
                    <span className="w-8 shrink-0 text-center font-mono text-sm text-muted">
                      #{i + 4}
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
          )}
        </>
      )}

      {!isRanked && rows.length > 0 && (
        <p className="mt-4 text-center text-sm text-muted">{t("notRanked")}</p>
      )}
    </div>
  );
}

function PodiumCard({
  row,
  spec,
  isMe,
  t,
}: {
  row: LeaderboardEntry;
  spec: (typeof PODIUM)[number];
  isMe: boolean;
  t: Awaited<ReturnType<typeof getTranslations>>;
}) {
  return (
    <div className={`flex-1 ${spec.order} ${spec.height}`}>
      <div
        className={`card ${isMe ? "glow-accent" : ""} flex flex-col items-center border-2 ${spec.ring} p-5 text-center`}
      >
        <span className="text-3xl">{spec.medal}</span>
        <p className={`mt-2 text-sm font-semibold ${isMe ? "text-accent" : ""}`}>
          {row.name}
          {isMe && <span className="ml-1 text-xs font-normal text-muted">{t("you")}</span>}
        </p>
        <p className="mt-1 font-mono text-xs text-muted">{t("levelXp", { level: row.level, xp: row.xp })}</p>
      </div>
    </div>
  );
}
