import type { Course, Lesson } from "@/lib/supabase/types";

export function LessonFormFields({
  courses,
  lesson,
}: {
  courses: Course[];
  lesson?: Lesson;
}) {
  const contentText = (lesson?.content ?? []).map((c) => c.text).join("\n\n---\n\n");

  return (
    <>
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-sm text-muted">Title</span>
          <input
            name="title"
            defaultValue={lesson?.title}
            required
            className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm text-muted">Slug</span>
          <input
            name="slug"
            defaultValue={lesson?.slug}
            required
            pattern="[a-z0-9-]+"
            className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm text-muted">Course</span>
          <select
            name="course_id"
            defaultValue={lesson?.course_id}
            required
            className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2"
          >
            {courses.map((c) => (
              <option key={c.id} value={c.id}>
                {c.title}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="text-sm text-muted">Difficulty</span>
          <select
            name="difficulty"
            defaultValue={lesson?.difficulty ?? "beginner"}
            className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2"
          >
            <option value="beginner">Beginner</option>
            <option value="intermediate">Intermediate</option>
            <option value="advanced">Advanced</option>
          </select>
        </label>
        <label className="block">
          <span className="text-sm text-muted">Sort order</span>
          <input
            name="sort_order"
            type="number"
            defaultValue={lesson?.sort_order ?? 1}
            required
            className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2"
          />
        </label>
        <label className="mt-6 flex items-center gap-2">
          <input type="checkbox" name="is_free" defaultChecked={lesson?.is_free ?? false} />
          <span className="text-sm">Free lesson</span>
        </label>
      </div>

      <label className="mt-4 block">
        <span className="text-sm text-muted">
          Content steps — separate each step with a line containing only ---
        </span>
        <textarea
          name="content"
          defaultValue={contentText}
          rows={6}
          className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 font-mono text-sm"
        />
      </label>

      <div className="mt-4 space-y-3">
        <p className="text-sm text-muted">
          Code editor — leave a language unchecked if it hasn&rsquo;t been introduced yet
        </p>
        {(["html", "css", "js"] as const).map((lang) => (
          <div key={lang}>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                name={`enable_${lang}`}
                defaultChecked={lesson?.starter_code?.[lang] !== undefined}
              />
              <span className="text-sm font-mono uppercase">{lang}</span>
            </label>
            <textarea
              name={`code_${lang}`}
              defaultValue={lesson?.starter_code?.[lang] ?? ""}
              rows={4}
              className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 font-mono text-sm"
            />
          </div>
        ))}
      </div>
    </>
  );
}
