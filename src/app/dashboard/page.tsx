import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { computeLessonAccess, hasPremiumAccess } from "@/lib/lessons";

const TRACKS = [
  { slug: "foundation", title: "Foundation" },
  { slug: "frontend", title: "Frontend Development" },
  { slug: "backend", title: "Backend Development" },
] as const;

export default async function DashboardPage() {
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

  const tracks = TRACKS.map((track) => {
    const course = courses?.find((c) => c.slug === track.slug);
    const lessonsInCourse = (lessons ?? []).filter(
      (l) => l.course_id === course?.id
    );
    const withAccess = computeLessonAccess(lessonsInCourse, completedIds, isPremium);
    const total = withAccess.length;
    const done = withAccess.filter((l) => l.access === "completed").length;
    const percent = total > 0 ? Math.round((done / total) * 100) : 0;
    const nextLesson = withAccess.find(
      (l) => l.access === "available" || l.access === "paywall"
    );
    return { ...track, total, done, percent, nextLesson };
  });

  const currentTrack =
    tracks.find((t) => t.total > 0 && t.percent < 100) ?? tracks[0];

  const name = profile?.name ?? "Student";

  return (
    <div className="mx-auto max-w-5xl px-6 py-10">
      <h1 className="text-2xl font-bold">Welcome, {name} 👋</h1>
      <p className="mt-1 text-muted">
        Your goal: <span className="text-foreground">Become a Full Stack Developer</span>
      </p>

      <section className="mt-8 rounded-xl border border-border bg-surface p-6">
        <p className="text-sm text-muted">Current Learning Path</p>
        <p className="mt-1 text-lg font-semibold">{currentTrack.title}</p>
        <p className="text-sm text-muted">
          {currentTrack.total > 0
            ? `Lesson ${currentTrack.done}/${currentTrack.total}`
            : "No lessons published yet — check back soon."}
        </p>
        {currentTrack.nextLesson && (
          <Link
            href={`/learn/${currentTrack.nextLesson.slug}`}
            className="mt-4 inline-block rounded-lg bg-accent px-5 py-2.5 text-sm font-semibold text-accent-foreground hover:opacity-90"
          >
            Continue learning &rarr;
          </Link>
        )}
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-3">
        {tracks.map((track) => (
          <div
            key={track.slug}
            className="rounded-xl border border-border bg-surface p-5"
          >
            <p className="text-sm font-semibold">{track.title}</p>
            <div className="mt-3 h-2 w-full overflow-hidden rounded-full bg-surface-2">
              <div
                className="h-full rounded-full bg-accent transition-all"
                style={{ width: `${track.percent}%` }}
              />
            </div>
            <p className="mt-2 text-xs text-muted">{track.percent}% complete</p>
          </div>
        ))}
      </section>

      <section className="mt-6 rounded-xl border border-accent/40 bg-accent/5 p-6">
        <p className="text-sm font-semibold text-accent">Today&rsquo;s Mission</p>
        <p className="mt-2 text-foreground">
          Create a button that changes color using JavaScript.
        </p>
        <p className="mt-1 text-sm text-muted">+20 XP</p>
      </section>
    </div>
  );
}
