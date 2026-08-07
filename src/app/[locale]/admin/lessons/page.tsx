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
        <Link
          href="/admin/lessons/new"
          className="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-accent-foreground hover:opacity-90"
        >
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
              <div className="mt-2 divide-y divide-border rounded-xl border border-border bg-surface">
                {courseLessons.map((lesson) => (
                  <Link
                    key={lesson.id}
                    href={`/admin/lessons/${lesson.id}`}
                    className="flex items-center justify-between px-4 py-3 text-sm hover:bg-surface-2"
                  >
                    <span>
                      {lesson.sort_order}. {lesson.title.en}
                    </span>
                    <span className="text-xs text-muted">
                      {lesson.is_free ? "Free" : "Pro"} · {lesson.difficulty}
                    </span>
                  </Link>
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
