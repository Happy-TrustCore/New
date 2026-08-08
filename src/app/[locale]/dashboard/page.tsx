import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";
import { computeLessonAccess, hasPremiumAccess } from "@/lib/lessons";
import { pickLocale } from "@/lib/i18n-content";
import { computeBadgeStatus } from "@/lib/achievements";

const TRACK_SLUGS = ["foundation", "frontend", "backend"] as const;

export default async function DashboardPage({
  params,
}: PageProps<"/[locale]/dashboard">) {
  const { locale } = (await params) as { locale: Locale };
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const [{ data: profile }, { data: courses }, { data: lessons }, { data: completed }] =
    await Promise.all([
      supabase.from("profiles").select("*").eq("id", user!.id).single(),
      supabase.from("courses").select("*").order("sort_order"),
      supabase.from("lessons").select("*"),
      supabase
        .from("lesson_progress")
        .select("lesson_id")
        .eq("user_id", user!.id)
        .eq("status", "completed"),
    ]);

  const completedIds = new Set((completed ?? []).map((row) => row.lesson_id));
  const isPremium = hasPremiumAccess(profile);

  const tracks = TRACK_SLUGS.map((slug) => {
    const course = courses?.find((c) => c.slug === slug);
    const lessonsInCourse = (lessons ?? []).filter((l) => l.course_id === course?.id);
    const withAccess = computeLessonAccess(lessonsInCourse, completedIds, isPremium);
    const total = withAccess.length;
    const done = withAccess.filter((l) => l.access === "completed").length;
    const percent = total > 0 ? Math.round((done / total) * 100) : 0;
    const nextLesson = withAccess.find(
      (l) => l.access === "available" || l.access === "paywall"
    );
    return {
      slug,
      title: course ? pickLocale(course.title, locale) : slug,
      total,
      done,
      percent,
      nextLesson,
    };
  });

  const currentTrack = tracks.find((t) => t.total > 0 && t.percent < 100) ?? tracks[0];
  const name = profile?.name ?? "Student";

  const completedSlugs = new Set(
    (lessons ?? []).filter((l) => completedIds.has(l.id)).map((l) => l.slug)
  );
  const badgeStatus = computeBadgeStatus(completedSlugs);

  return (
    <DashboardBody
      name={name}
      currentTrack={currentTrack}
      tracks={tracks}
      badgeStatus={badgeStatus}
    />
  );
}

type Track = {
  slug: string;
  title: string;
  total: number;
  done: number;
  percent: number;
  nextLesson?: { slug: string };
};

function DashboardBody({
  name,
  currentTrack,
  tracks,
  badgeStatus,
}: {
  name: string;
  currentTrack: Track;
  tracks: Track[];
  badgeStatus: ReturnType<typeof computeBadgeStatus>;
}) {
  const t = useTranslations("dashboard");

  return (
    <div className="mx-auto max-w-5xl px-6 py-10">
      <h1 className="text-2xl font-bold">
        {t("welcome", { name })} 👋
      </h1>
      <p className="mt-1 text-muted">
        {t("goalLabel")} <span className="text-foreground">{t("goalValue")}</span>
      </p>

      <section className="mt-8 rounded-xl border border-border bg-surface p-6">
        <p className="text-sm text-muted">{t("currentPath")}</p>
        <p className="mt-1 text-lg font-semibold">{currentTrack.title}</p>
        <p className="text-sm text-muted">
          {currentTrack.total > 0
            ? t("lessonProgress", { done: currentTrack.done, total: currentTrack.total })
            : t("noLessons")}
        </p>
        {currentTrack.nextLesson && (
          <Link
            href={`/learn/${currentTrack.nextLesson.slug}`}
            className="mt-4 inline-block rounded-lg bg-accent px-5 py-2.5 text-sm font-semibold text-accent-foreground hover:opacity-90"
          >
            {t("continueLearning")} &rarr;
          </Link>
        )}
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-3">
        {tracks.map((track) => (
          <div key={track.slug} className="rounded-xl border border-border bg-surface p-5">
            <p className="text-sm font-semibold">{track.title}</p>
            <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-surface-2">
              <div
                className="h-full rounded-full bg-accent transition-all"
                style={{ width: `${track.percent}%` }}
              />
            </div>
            <p className="mt-2 text-xs text-muted">{t("percentComplete", { percent: track.percent })}</p>
          </div>
        ))}
      </section>

      <section className="mt-6 rounded-xl border border-accent/40 bg-accent/5 p-6">
        <p className="text-sm font-semibold text-accent">{t("dailyMission")}</p>
        <p className="mt-2 text-foreground">{t("dailyMissionExample")}</p>
        <p className="mt-1 text-sm text-muted">+20 XP</p>
      </section>

      <section className="mt-6">
        <p className="text-sm font-semibold">{t("achievements.title")}</p>
        <div className="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-4">
          {badgeStatus.map(({ badge, earned }) => (
            <div
              key={badge.id}
              className={`rounded-xl border p-4 text-center ${
                earned
                  ? "border-accent/40 bg-accent/5"
                  : "border-border bg-surface opacity-40 grayscale"
              }`}
            >
              <span className="text-2xl">{badge.icon}</span>
              <p className="mt-2 text-xs font-semibold">
                {t(`achievements.badges.${badge.id}.title`)}
              </p>
              <p className="mt-1 text-[11px] text-muted">
                {t(`achievements.badges.${badge.id}.desc`)}
              </p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
