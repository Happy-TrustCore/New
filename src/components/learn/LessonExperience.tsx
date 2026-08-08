"use client";

import { useState } from "react";
import { LessonContent } from "./LessonContent";
import { QuizPanel } from "./QuizPanel";
import { PracticeDock } from "./PracticeDock";
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
}) {
  const [dockOpen, setDockOpen] = useState(false);

  return (
    <div className="flex h-full flex-col overflow-hidden">
      <div className="min-h-0 flex-1 overflow-y-auto">
        <div className="mx-auto max-w-3xl">
          <LessonContent
            title={title}
            difficulty={difficulty}
            steps={steps}
            onReachLast={() => setDockOpen(true)}
          />
          {quizQuestions.length > 0 && (
            <QuizPanel lessonId={lessonId} questions={quizQuestions} alreadyPassed={quizPassed} />
          )}
        </div>
      </div>
      <PracticeDock
        open={!paywalled && dockOpen}
        onToggle={() => setDockOpen((o) => !o)}
        paywalled={paywalled}
        lessonId={lessonId}
        starterCode={starterCode}
        practicePassed={practicePassed}
        hasAssignment={hasAssignment}
        assignmentPassed={assignmentPassed}
        isPremium={isPremium}
      />
    </div>
  );
}
