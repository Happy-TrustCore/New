import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { computeLessonAccess, hasPremiumAccess } from "@/lib/lessons";
import { LessonSidebar } from "@/components/learn/LessonSidebar";
import { LessonContent } from "@/components/learn/LessonContent";
import { QuizPanel } from "@/components/learn/QuizPanel";
import { CodeWorkspace } from "@/components/learn/CodeWorkspace";

export default async function LessonPage({
  params,
}: PageProps<"/learn/[lessonSlug]">) {
  const { lessonSlug } = await params;
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: lesson } = await supabase
    .from("lessons")
    .select("*")
    .eq("slug", lessonSlug)
    .single();

  if (!lesson) {
    notFound();
  }

  const [
    { data: course },
    { data: courseLessons },
    { data: completedRows },
    { data: profile },
    { data: myProgress },
    { data: quizQuestions },
  ] = await Promise.all([
    supabase.from("courses").select("*").eq("id", lesson.course_id).single(),
    supabase.from("lessons").select("*").eq("course_id", lesson.course_id),
    supabase
      .from("lesson_progress")
      .select("lesson_id")
      .eq("user_id", user.id)
      .eq("status", "completed"),
    supabase.from("profiles").select("*").eq("id", user.id).single(),
    supabase
      .from("lesson_progress")
      .select("*")
      .eq("user_id", user.id)
      .eq("lesson_id", lesson.id)
      .maybeSingle(),
    supabase
      .from("quiz_questions")
      .select("id, question, choices")
      .eq("lesson_id", lesson.id)
      .order("sort_order"),
  ]);

  const completedIds = new Set((completedRows ?? []).map((row) => row.lesson_id));
  const withAccess = computeLessonAccess(
    courseLessons ?? [],
    completedIds,
    hasPremiumAccess(profile)
  );
  const target = withAccess.find((l) => l.id === lesson.id);

  if (!target) {
    notFound();
  }

  if (target.access === "locked") {
    const firstReachable = withAccess.find(
      (l) => l.access === "available" || l.access === "paywall"
    );
    redirect(firstReachable ? `/learn/${firstReachable.slug}` : "/dashboard");
  }

  return (
    <div className="grid h-full grid-cols-[240px_1fr_1fr] overflow-hidden">
      <LessonSidebar
        courseTitle={course?.title ?? ""}
        lessons={withAccess}
        currentLessonId={lesson.id}
      />
      <div className="overflow-y-auto border-r border-border">
        <LessonContent
          title={lesson.title}
          difficulty={lesson.difficulty}
          steps={lesson.content}
        />
        {quizQuestions && quizQuestions.length > 0 && (
          <QuizPanel
            lessonId={lesson.id}
            questions={quizQuestions}
            alreadyPassed={myProgress?.quiz_passed ?? false}
          />
        )}
      </div>
      <div className="overflow-hidden">
        {target.access === "paywall" ? (
          <div className="flex h-full flex-col items-center justify-center gap-4 p-8 text-center">
            <p className="text-lg font-semibold">This lesson needs CodePath Pro</p>
            <p className="max-w-xs text-sm text-muted">
              You&rsquo;ve completed all free lessons in this course. Upgrade for
              €4.99/month to keep going.
            </p>
            <Link
              href="/#pricing"
              className="rounded-lg bg-accent px-5 py-2.5 text-sm font-semibold text-accent-foreground hover:opacity-90"
            >
              See plans
            </Link>
          </div>
        ) : (
          <CodeWorkspace
            lessonId={lesson.id}
            starterCode={lesson.starter_code}
            practicePassed={myProgress?.practice_passed ?? false}
          />
        )}
      </div>
    </div>
  );
}
