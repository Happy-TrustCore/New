import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { updateLesson, deleteLesson, addQuizQuestion, deleteQuizQuestion } from "@/lib/actions/admin";
import { LessonFormFields } from "@/components/admin/LessonFormFields";

export default async function EditLessonPage({
  params,
  searchParams,
}: PageProps<"/admin/lessons/[id]">) {
  const { id } = await params;
  const sp = await searchParams;
  const error = typeof sp.error === "string" ? sp.error : null;

  const supabase = await createClient();
  const [{ data: lesson }, { data: courses }, { data: questions }] = await Promise.all([
    supabase.from("lessons").select("*").eq("id", id).single(),
    supabase.from("courses").select("*").order("sort_order"),
    supabase.from("quiz_questions").select("*").eq("lesson_id", id).order("sort_order"),
  ]);

  if (!lesson) {
    notFound();
  }

  return (
    <div className="max-w-2xl pb-16">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Edit lesson</h1>
        <form action={deleteLesson.bind(null, id)}>
          <button type="submit" className="text-sm text-red-400 hover:underline">
            Delete lesson
          </button>
        </form>
      </div>
      {error && (
        <p className="mt-4 rounded-lg border border-red-500/40 bg-red-500/10 px-4 py-2 text-sm text-red-400">
          {error}
        </p>
      )}
      <form action={updateLesson.bind(null, id)} className="mt-6">
        <LessonFormFields courses={courses ?? []} lesson={lesson} />
        <button
          type="submit"
          className="mt-6 rounded-lg bg-accent px-5 py-2.5 text-sm font-semibold text-accent-foreground hover:opacity-90"
        >
          Save changes
        </button>
      </form>

      <div className="mt-10 border-t border-border pt-6">
        <h2 className="text-lg font-semibold">Quiz questions</h2>
        <div className="mt-3 space-y-3">
          {(questions ?? []).map((q) => (
            <div key={q.id} className="rounded-lg border border-border bg-surface p-4">
              <div className="flex items-start justify-between gap-4">
                <p className="text-sm font-medium">{q.question}</p>
                <form action={deleteQuizQuestion.bind(null, id, q.id)}>
                  <button type="submit" className="shrink-0 text-xs text-red-400 hover:underline">
                    Delete
                  </button>
                </form>
              </div>
              <ul className="mt-2 space-y-1 text-xs text-muted">
                {q.choices.map((c, i) => (
                  <li key={i} className={i === q.correct_index ? "text-accent" : ""}>
                    {c}
                    {i === q.correct_index ? " (correct)" : ""}
                  </li>
                ))}
              </ul>
            </div>
          ))}
          {(questions ?? []).length === 0 && (
            <p className="text-sm text-muted">No quiz questions yet.</p>
          )}
        </div>

        <form
          action={addQuizQuestion.bind(null, id)}
          className="mt-6 space-y-3 rounded-lg border border-border bg-surface p-4"
        >
          <p className="text-sm font-semibold">Add a question</p>
          <input
            name="question"
            placeholder="Question text"
            required
            className="w-full rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm"
          />
          {[0, 1, 2, 3].map((i) => (
            <div key={i} className="flex items-center gap-2">
              <input type="radio" name="correct_index" value={i} required={i === 0} />
              <input
                name={`choice_${i}`}
                placeholder={`Choice ${i + 1}`}
                required={i < 2}
                className="flex-1 rounded-lg border border-border bg-surface-2 px-3 py-2 text-sm"
              />
            </div>
          ))}
          <button
            type="submit"
            className="rounded-lg bg-accent px-4 py-2 text-sm font-semibold text-accent-foreground hover:opacity-90"
          >
            Add question
          </button>
        </form>
      </div>
    </div>
  );
}
