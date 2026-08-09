import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";
import { computeLessonAccess, hasPremiumAccess } from "@/lib/lessons";
import { pickLocale } from "@/lib/i18n-content";
import { computeBadgeStatus } from "@/lib/achievements";
import { startCheckout, manageBilling } from "@/lib/actions/billing";

const TRACK_SLUGS = ["foundation", "frontend", "backend", "tools"] as const;

export default async function DashboardPage({
  params,
}: PageProps<"/[locale]/dashboard">) {
  const { locale } = (await params) as { locale: Locale };
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const [
    { data: profile },
    { data: courses },
    { data: lessons },
    { data: completed },
    { data: projects },
    { data: certificates },
  ] = await Promise.all([
    supabase.from("profiles").select("*").eq("id", user!.id).single(),
    supabase.from("courses").select("*").order("sort_order"),
    supabase.from("lessons").select("*"),
    supabase
      .from("lesson_progress")
      .select("lesson_id")
      .eq("user_id", user!.id)
      .eq("status", "completed"),
    supabase
      .from("projects")
      .select("*")
      .eq("user_id", user!.id)
      .order("submitted_at", { ascending: false }),
    supabase
      .from("certificates")
      .select("*")
      .eq("user_id", user!.id)
      .order("issued_at", { ascending: false }),
  ]);

  const completedIds = new Set((completed ?? []).map((row) => row.lesson_id));
  const isPremium = hasPremiumAccess(profile);
  const isAdmin = profile?.is_admin ?? false;

  const tracks = TRACK_SLUGS.map((slug) => {
    const course = courses?.find((c) => c.slug === slug);
    const lessonsInCourse = (lessons ?? []).filter((l) => l.course_id === course?.id);
    const withAccess = computeLessonAccess(lessonsInCourse, completedIds, isPremium, isAdmin);
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

  const foundationTrack = tracks.find((t) => t.slug === "foundation");
  const frontendTrack = tracks.find((t) => t.slug === "frontend");
  const backendTrack = tracks.find((t) => t.slug === "backend");
  const foundationDone =
    !!foundationTrack && foundationTrack.total > 0 && foundationTrack.done === foundationTrack.total;
  // Foundation is the only track that must come first — Frontend and
  // Backend are independently unlocked (computeLessonAccess never checks
  // across courses), so once Foundation is done and neither has been
  // touched yet, let the student pick instead of defaulting to Frontend.
  const showPathChoice =
    foundationDone && !!frontendTrack && !!backendTrack && frontendTrack.done === 0 && backendTrack.done === 0;

  const currentTrack = tracks.find((t) => t.total > 0 && t.percent < 100) ?? tracks[0];
  const name = profile?.name ?? "Student";

  const completedSlugs = new Set(
    (lessons ?? []).filter((l) => completedIds.has(l.id)).map((l) => l.slug)
  );
  const badgeStatus = computeBadgeStatus(completedSlugs);

  const portfolio = (projects ?? []).map((p) => {
    const lesson = lessons?.find((l) => l.id === p.lesson_id);
    return {
      id: p.id,
      title: p.title,
      lessonSlug: lesson?.slug,
      submittedAt: p.submitted_at,
    };
  });

  const earnedCertificates = (certificates ?? []).map((c) => {
    const course = courses?.find((course) => course.id === c.course_id);
    return {
      id: c.id,
      courseTitle: course ? pickLocale(course.title, locale) : "",
      issuedAt: c.issued_at,
    };
  });

  return (
    <DashboardBody
      name={name}
      currentTrack={currentTrack}
      tracks={tracks}
      badgeStatus={badgeStatus}
      portfolio={portfolio}
      certificates={earnedCertificates}
      isPremium={isPremium}
      currentStreak={profile?.current_streak ?? 0}
      longestStreak={profile?.longest_streak ?? 0}
      showPathChoice={showPathChoice}
      frontendTrack={frontendTrack}
      backendTrack={backendTrack}
      isAdmin={isAdmin}
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

type PortfolioItem = {
  id: string;
  title: string;
  lessonSlug?: string;
  submittedAt: string;
};

type CertificateItem = {
  id: string;
  courseTitle: string;
  issuedAt: string;
};

function DashboardBody({
  name,
  currentTrack,
  tracks,
  badgeStatus,
  portfolio,
  certificates,
  isPremium,
  currentStreak,
  longestStreak,
  showPathChoice,
  frontendTrack,
  backendTrack,
  isAdmin,
}: {
  name: string;
  currentTrack: Track;
  tracks: Track[];
  badgeStatus: ReturnType<typeof computeBadgeStatus>;
  portfolio: PortfolioItem[];
  certificates: CertificateItem[];
  isPremium: boolean;
  currentStreak: number;
  longestStreak: number;
  showPathChoice: boolean;
  frontendTrack?: Track;
  backendTrack?: Track;
  isAdmin: boolean;
}) {
  const t = useTranslations("dashboard");

  return (
    <div className="mx-auto max-w-5xl px-6 py-10">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">
            {t("welcome", { name })} 👋
          </h1>
          <p className="mt-1 text-muted">
            {t("goalLabel")} <span className="text-foreground">{t("goalValue")}</span>
          </p>
        </div>
        {currentStreak > 0 && (
          <div className="pill flex items-center gap-2 px-4 py-2">
            <span className="text-lg">🔥</span>
            <div>
              <p className="text-sm font-semibold text-accent-warm">
                {t("streak.current", { days: currentStreak })}
              </p>
              {longestStreak > currentStreak && (
                <p className="text-xs text-muted">{t("streak.longest", { days: longestStreak })}</p>
              )}
            </div>
          </div>
        )}
      </div>

      {showPathChoice && frontendTrack && backendTrack ? (
        <section className="mt-8">
          <p className="text-sm text-muted">{t("choosePath.label")}</p>
          <div className="mt-3 grid gap-4 sm:grid-cols-2">
            {[
              { track: frontendTrack, icon: "🎨", desc: t("choosePath.frontendDesc") },
              { track: backendTrack, icon: "🗄️", desc: t("choosePath.backendDesc") },
            ].map(({ track, icon, desc }) => (
              <div key={track.slug} className="card card-hover flex flex-col p-6">
                <span className="text-2xl">{icon}</span>
                <p className="mt-2 text-lg font-semibold">{track.title}</p>
                <p className="mt-2 flex-1 text-sm text-muted">{desc}</p>
                {track.nextLesson && (
                  <Link
                    href={`/learn/${track.nextLesson.slug}`}
                    className="btn-primary mt-4 inline-block w-fit rounded-lg px-5 py-2 text-sm"
                  >
                    {t("choosePath.cta")} &rarr;
                  </Link>
                )}
              </div>
            ))}
          </div>
        </section>
      ) : (
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
              className="btn-primary mt-4 inline-block rounded-lg px-5 py-2.5 text-sm"
            >
              {t("continueLearning")} &rarr;
            </Link>
          )}
        </section>
      )}

      <section className="mt-6 grid gap-4 sm:grid-cols-3">
        {tracks.map((track) => {
          const body = (
            <>
              <p className="text-sm font-semibold">{track.title}</p>
              <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-surface-2">
                <div
                  className="h-full rounded-full bg-accent transition-all"
                  style={{ width: `${track.percent}%` }}
                />
              </div>
              <p className="mt-2 text-xs text-muted">{t("percentComplete", { percent: track.percent })}</p>
            </>
          );
          // Admins get a direct entry point into every track from here —
          // students stay funneled through the single "continue" CTA above,
          // which is the intended sequential flow for them.
          if (isAdmin && track.nextLesson) {
            return (
              <Link
                key={track.slug}
                href={`/learn/${track.nextLesson.slug}`}
                className="card card-hover rounded-xl border border-border p-5"
              >
                {body}
              </Link>
            );
          }
          return (
            <div key={track.slug} className="rounded-xl border border-border bg-surface p-5">
              {body}
            </div>
          );
        })}
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

      <section className="mt-6">
        <p className="text-sm font-semibold">{t("certificates.title")}</p>
        {certificates.length === 0 ? (
          <div className="mt-3 flex flex-col items-center gap-2 rounded-xl border border-border bg-surface px-6 py-10 text-center">
            <span className="text-2xl">🏆</span>
            <p className="text-sm text-muted">{t("certificates.empty")}</p>
          </div>
        ) : (
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            {certificates.map((cert) => (
              <Link
                key={cert.id}
                href={`/certificate/${cert.id}`}
                className="card card-hover flex items-center justify-between p-4"
              >
                <div>
                  <p className="text-sm font-semibold">{cert.courseTitle}</p>
                  <p className="mt-1 text-xs text-muted">
                    {new Date(cert.issuedAt).toLocaleDateString()}
                  </p>
                </div>
                <span className="text-lg">🏆</span>
              </Link>
            ))}
          </div>
        )}
      </section>

      <section className="mt-6 glow-accent card flex items-center justify-between p-6">
        {isPremium ? (
          <>
            <div>
              <p className="text-sm font-semibold text-accent">{t("billing.proTitle")}</p>
              <p className="mt-1 text-sm text-muted">{t("billing.proBlurb")}</p>
            </div>
            <form action={manageBilling}>
              <button type="submit" className="shrink-0 rounded-lg border border-border px-4 py-2 text-sm transition hover:bg-surface-2">
                {t("billing.manage")}
              </button>
            </form>
          </>
        ) : (
          <>
            <div>
              <p className="text-sm font-semibold text-accent">{t("billing.freeTitle")}</p>
              <p className="mt-1 text-sm text-muted">{t("billing.freeBlurb")}</p>
            </div>
            <form action={startCheckout}>
              <button type="submit" className="btn-primary shrink-0 rounded-lg px-4 py-2 text-sm">
                {t("billing.upgrade")}
              </button>
            </form>
          </>
        )}
      </section>

      <section className="mt-6 card flex items-center justify-between p-6">
        <div>
          <p className="text-sm font-semibold text-accent">{t("marketplace.title")}</p>
          <p className="mt-1 text-sm text-muted">{t("marketplace.blurb")}</p>
        </div>
        <Link
          href="/marketplace"
          className="btn-primary shrink-0 rounded-lg px-4 py-2 text-sm"
        >
          {t("marketplace.cta")}
        </Link>
      </section>

      <section className="mt-6">
        <p className="text-sm font-semibold">{t("portfolio.title")}</p>
        {portfolio.length === 0 ? (
          <div className="mt-3 flex flex-col items-center gap-2 rounded-xl border border-border bg-surface px-6 py-10 text-center">
            <span className="text-2xl">💼</span>
            <p className="text-sm text-muted">{t("portfolio.empty")}</p>
          </div>
        ) : (
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            {portfolio.map((item) => (
              <div key={item.id} className="card card-hover p-4">
                <p className="text-sm font-semibold">{item.title}</p>
                <p className="mt-1 text-xs text-muted">
                  {new Date(item.submittedAt).toLocaleDateString()}
                </p>
                {item.lessonSlug && (
                  <Link
                    href={`/learn/${item.lessonSlug}`}
                    className="mt-2 inline-block text-xs text-accent hover:underline"
                  >
                    {t("portfolio.viewLesson")} &rarr;
                  </Link>
                )}
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}
