import { redirect } from "@/i18n/navigation";
import { notFound } from "next/navigation";
import type { Locale } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";
import { computeLessonAccess, hasPremiumAccess } from "@/lib/lessons";
import { pickLocale } from "@/lib/i18n-content";
import { LessonSidebar } from "@/components/learn/LessonSidebar";
import { LessonExperience } from "@/components/learn/LessonExperience";

export default async function LessonPage({
  params,
  searchParams,
}: PageProps<"/[locale]/learn/[lessonSlug]">) {
  const { locale, lessonSlug } = (await params) as { locale: Locale; lessonSlug: string };
  const sp = await searchParams;
  const initialMode = sp.start === "practice" ? "practice" : "lesson";
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
    { data: courseProgressRows },
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
    supabase
      .from("lesson_progress")
      .select("lesson_id, content_viewed")
      .eq("user_id", user.id)
      .eq("content_viewed", true),
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
  const contentViewedIds = new Set((courseProgressRows ?? []).map((row) => row.lesson_id));
  const isPremium = hasPremiumAccess(profile);
  const isAdmin = profile?.is_admin ?? false;
  const withAccess = computeLessonAccess(courseLessons ?? [], completedIds, isPremium, isAdmin);
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

  const targetIndex = withAccess.findIndex((l) => l.id === lesson.id);
  const nextLessonSlug = withAccess[targetIndex + 1]?.slug ?? null;

  // Direct-URL safety net: only honor ?start=practice if the reading part
  // was actually already viewed (or the lesson is already fully done) —
  // otherwise fall back to the reading screen, same as the sidebar link logic.
  const canStartAtPractice = contentViewedIds.has(lesson.id) || target.access === "completed";
  const resolvedInitialMode = initialMode === "practice" && canStartAtPractice ? "practice" : "lesson";

  return (
    <div className="grid h-full grid-rows-[auto_1fr] overflow-hidden sm:grid-cols-[240px_1fr] sm:grid-rows-1">
      <LessonSidebar
        courseTitle={course ? pickLocale(course.title, locale) : ""}
        lessons={withAccess}
        currentLessonId={lesson.id}
        currentMode={resolvedInitialMode}
        contentViewedIds={contentViewedIds}
      />
      <LessonExperience
        title={lesson.title}
        difficulty={lesson.difficulty}
        steps={lesson.content}
        quizQuestions={quizQuestions ?? []}
        quizPassed={myProgress?.quiz_passed ?? false}
        lessonId={lesson.id}
        starterCode={lesson.starter_code}
        practicePassed={myProgress?.practice_passed ?? false}
        hasAssignment={lesson.has_assignment}
        assignmentPassed={myProgress?.assignment_passed ?? false}
        initialMode={resolvedInitialMode}
        paywalled={target.access === "paywall"}
        isPremium={isPremium}
        nextLessonSlug={nextLessonSlug}
      />
    </div>
  );
}
