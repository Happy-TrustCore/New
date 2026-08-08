import type { Course, Lesson } from "@/lib/supabase/types";

export function LessonFormFields({
  courses,
  lesson,
}: {
  courses: Course[];
  lesson?: Lesson;
}) {
  const contentTextEn = (lesson?.content ?? []).map((c) => c.text.en).join("\n\n---\n\n");
  const contentTextDe = (lesson?.content ?? []).map((c) => c.text.de).join("\n\n---\n\n");

  return (
    <>
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-sm text-muted">Title (English)</span>
          <input
            name="title_en"
            defaultValue={lesson?.title.en}
            required
            className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm text-muted">Title (German)</span>
          <input
            name="title_de"
            defaultValue={lesson?.title.de}
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
                {c.title.en}
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
        <label className="mt-6 flex items-center gap-2">
          <input
            type="checkbox"
            name="has_assignment"
            defaultChecked={lesson?.has_assignment ?? false}
          />
          <span className="text-sm">Requires a project submission (assignment)</span>
        </label>
      </div>

      <div className="mt-4 grid gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="text-sm text-muted">
            Content steps (English) — separate each step with a line containing only ---
          </span>
          <textarea
            name="content_en"
            defaultValue={contentTextEn}
            rows={8}
            className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 font-mono text-sm"
          />
        </label>
        <label className="block">
          <span className="text-sm text-muted">
            Content steps (German) — same number of steps, same order
          </span>
          <textarea
            name="content_de"
            defaultValue={contentTextDe}
            rows={8}
            className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 font-mono text-sm"
          />
        </label>
      </div>

      <div className="mt-4 space-y-3">
        <p className="text-sm text-muted">
          Code editor — leave a language unchecked if it hasn&rsquo;t been introduced yet.
          Code itself is not translated.
        </p>
        {(["html", "css", "js", "jsx"] as const).map((lang) => (
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
