"use client";

import { useState } from "react";
import { LessonContent } from "./LessonContent";
import { PracticeScreen } from "./PracticeScreen";
import { QuizScreen } from "./QuizScreen";
import { markContentViewed } from "@/lib/actions/progress";
import type {
  Difficulty,
  LessonContentBlock,
  LocalizedChoices,
  LocalizedText,
  StarterCode,
} from "@/lib/supabase/types";

type QuizQuestionPublic = {
  id: string;
  question: LocalizedText;
  choices: LocalizedChoices;
};

type Mode = "lesson" | "practice" | "quiz";

export function LessonExperience({
  title,
  difficulty,
  steps,
  quizQuestions,
  quizPassed,
  lessonId,
  starterCode,
  practicePassed,
  hasAssignment,
  assignmentPassed,
  paywalled,
  isPremium,
  nextLessonSlug,
  initialMode = "lesson",
}: {
  title: LocalizedText;
  difficulty: Difficulty;
  steps: LessonContentBlock[];
  quizQuestions: QuizQuestionPublic[];
  quizPassed: boolean;
  lessonId: string;
  starterCode: StarterCode | null;
  practicePassed: boolean;
  hasAssignment: boolean;
  assignmentPassed: boolean;
  paywalled: boolean;
  isPremium: boolean;
  nextLessonSlug: string | null;
  initialMode?: Mode;
}) {
  const [mode, setMode] = useState<Mode>(initialMode);
  const hasQuiz = quizQuestions.length > 0;
  const taskText = steps.length > 0 ? steps[steps.length - 1].text : null;

  function goToPractice() {
    setMode("practice");
    markContentViewed(lessonId).catch(() => {});
  }

  if (mode === "practice") {
    return (
      <PracticeScreen
        lessonTitle={title}
        taskText={taskText}
        paywalled={paywalled}
        lessonId={lessonId}
        starterCode={starterCode}
        practicePassed={practicePassed}
        hasAssignment={hasAssignment}
        assignmentPassed={assignmentPassed}
        isPremium={isPremium}
        hasQuiz={hasQuiz}
        nextLessonSlug={nextLessonSlug}
        onBackToLesson={() => setMode("lesson")}
        onContinueToQuiz={() => setMode("quiz")}
      />
    );
  }

  if (mode === "quiz") {
    return (
      <QuizScreen
        lessonId={lessonId}
        questions={quizQuestions}
        alreadyPassed={quizPassed}
        nextLessonSlug={nextLessonSlug}
        onBackToPractice={() => setMode("practice")}
      />
    );
  }

  return (
    <div className="h-full overflow-y-auto">
      <div className="mx-auto max-w-3xl">
        <LessonContent
          title={title}
          difficulty={difficulty}
          steps={steps}
          onStartPractice={goToPractice}
        />
      </div>
    </div>
  );
}
