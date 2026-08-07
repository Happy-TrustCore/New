import { createClient } from "@/lib/supabase/server";
import { createLesson } from "@/lib/actions/admin";
import { LessonFormFields } from "@/components/admin/LessonFormFields";

export default async function NewLessonPage({
  searchParams,
}: PageProps<"/[locale]/admin/lessons/new">) {
  const params = await searchParams;
  const error = typeof params.error === "string" ? params.error : null;

  const supabase = await createClient();
  const { data: courses } = await supabase.from("courses").select("*").order("sort_order");

  return (
    <div className="max-w-2xl pb-16">
      <h1 className="text-2xl font-bold">New lesson</h1>
      {error && (
        <p className="mt-4 rounded-lg border border-red-500/40 bg-red-500/10 px-4 py-2 text-sm text-red-400">
          {error}
        </p>
      )}
      <form action={createLesson} className="mt-6">
        <LessonFormFields courses={courses ?? []} />
        <button
          type="submit"
          className="mt-6 rounded-lg bg-accent px-5 py-2.5 text-sm font-semibold text-accent-foreground hover:opacity-90"
        >
          Create lesson
        </button>
      </form>
    </div>
  );
}
