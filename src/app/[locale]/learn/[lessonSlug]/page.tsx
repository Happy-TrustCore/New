import { useTranslations } from "next-intl";
import { notFound } from "next/navigation";
import { Link, redirect } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";
import { computeLessonAccess, hasPremiumAccess } from "@/lib/lessons";
import { pickLocale } from "@/lib/i18n-content";
import { LessonSidebar } from "@/components/learn/LessonSidebar";
import { LessonContent } from "@/components/learn/LessonContent";
import { QuizPanel } from "@/components/learn/QuizPanel";
import { CodeWorkspace } from "@/components/learn/CodeWorkspace";

export default async function LessonPage({
  params,
}: PageProps<"/[locale]/learn/[lessonSlug]">) {
  const { locale, lessonSlug } = (await params) as { locale: Locale; lessonSlug: string };
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return redirect({ href: "/login", locale });
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
    redirect({
      href: firstReachable ? `/learn/${firstReachable.slug}` : "/dashboard",
      locale,
    });
  }

  return (
    <div className="grid h-full grid-cols-[240px_1fr_1fr] overflow-hidden">
      <LessonSidebar
        courseTitle={course ? pickLocale(course.title, locale) : ""}
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
          <PaywallPanel />
        ) : (
          <CodeWorkspace
            lessonId={lesson.id}
            starterCode={lesson.starter_code}
            practicePassed={myProgress?.practice_passed ?? false}
            hasAssignment={lesson.has_assignment}
            assignmentPassed={myProgress?.assignment_passed ?? false}
          />
        )}
      </div>
    </div>
  );
}

function PaywallPanel() {
  const t = useTranslations("learn.paywall");

  return (
    <div className="flex h-full flex-col items-center justify-center gap-4 p-8 text-center">
      <p className="text-lg font-semibold">{t("title")}</p>
      <p className="max-w-xs text-sm text-muted">{t("body")}</p>
      <Link
        href="/#pricing"
        className="rounded-lg bg-accent px-5 py-2.5 text-sm font-semibold text-accent-foreground hover:opacity-90"
      >
        {t("cta")}
      </Link>
    </div>
  );
}
