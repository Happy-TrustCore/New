import { Link } from "@/i18n/navigation";
import { createClient } from "@/lib/supabase/server";

export default async function AdminLessonsPage() {
  const supabase = await createClient();
  const [{ data: courses }, { data: lessons }] = await Promise.all([
    supabase.from("courses").select("*").order("sort_order"),
    supabase.from("lessons").select("*").order("sort_order"),
  ]);

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Lessons</h1>
        <Link href="/admin/lessons/new" className="btn-primary rounded-lg px-4 py-2 text-sm">
          + New lesson
        </Link>
      </div>

      <div className="mt-6 space-y-8">
        {(courses ?? []).map((course) => {
          const courseLessons = (lessons ?? []).filter((l) => l.course_id === course.id);
          return (
            <div key={course.id}>
              <h2 className="text-sm font-semibold uppercase tracking-wide text-muted">
                {course.title.en}
              </h2>
              <div className="card mt-2 divide-y divide-border">
                {courseLessons.map((lesson) => (
                  <div
                    key={lesson.id}
                    className="flex items-center justify-between gap-3 px-4 py-3 text-sm transition hover:bg-surface-2"
                  >
                    <Link href={`/admin/lessons/${lesson.id}`} className="min-w-0 flex-1 truncate">
                      {lesson.sort_order}. {lesson.title.en}
                    </Link>
                    <span className="shrink-0 text-xs text-muted">
                      {lesson.is_free ? "Free" : "Pro"} · {lesson.difficulty}
                    </span>
                    <a
                      href={`/learn/${lesson.slug}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="shrink-0 rounded-lg border border-border px-2.5 py-1 text-xs text-accent transition hover:bg-surface-2"
                    >
                      Preview &rarr;
                    </a>
                  </div>
                ))}
                {courseLessons.length === 0 && (
                  <p className="px-4 py-3 text-sm text-muted">No lessons yet.</p>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
