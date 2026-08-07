// Hand-written types mirroring db/schema.sql.
// If the schema changes, update this file to match.
//
// NOTE: these must be `type` aliases, not `interface`s — Supabase's generic
// constraints check each Row against `Record<string, unknown>`, and
// TypeScript only treats plain object type aliases (not interfaces) as
// satisfying that structurally.

export type AccountType = "free" | "premium" | "student";
export type SubscriptionPlan = "free" | "premium" | "student";
export type SubscriptionStatus = "active" | "canceled" | "expired";
export type Difficulty = "beginner" | "intermediate" | "advanced";
export type ProgressStatus = "in_progress" | "completed";

export type Profile = {
  id: string;
  name: string;
  email: string;
  account_type: AccountType;
  student_verified_until: string | null;
  xp: number;
  level: number;
  is_admin: boolean;
  created_at: string;
};

// Bilingual text fields, e.g. { "en": "Hello", "de": "Hallo" }.
export type LocalizedText = { en: string; de: string };

// Bilingual choice lists — arrays must stay the same length/order across
// locales, since correct_index refers to a position, not a specific list.
export type LocalizedChoices = { en: string[]; de: string[] };

export type Course = {
  id: string;
  slug: string;
  title: LocalizedText;
  description: LocalizedText | null;
  sort_order: number;
};

export type LessonContentBlock = {
  step: number;
  text: LocalizedText;
};

export type StarterCode = {
  html?: string;
  css?: string;
  js?: string;
};

export type Lesson = {
  id: string;
  course_id: string;
  slug: string;
  title: LocalizedText;
  content: LessonContentBlock[];
  starter_code: StarterCode | null;
  difficulty: Difficulty;
  is_free: boolean;
  sort_order: number;
  created_at: string;
};

export type QuizQuestion = {
  id: string;
  lesson_id: string;
  question: LocalizedText;
  choices: LocalizedChoices;
  correct_index: number;
  sort_order: number;
};

export type LessonProgress = {
  id: string;
  user_id: string;
  lesson_id: string;
  status: ProgressStatus;
  practice_passed: boolean;
  quiz_passed: boolean;
  assignment_passed: boolean;
  completed_at: string | null;
  updated_at: string;
};

export type Project = {
  id: string;
  user_id: string;
  lesson_id: string | null;
  title: string;
  code: StarterCode | null;
  submitted_at: string;
};

export type Subscription = {
  id: string;
  user_id: string;
  plan: SubscriptionPlan;
  status: SubscriptionStatus;
  current_period_end: string | null;
  created_at: string;
};

type NoRelationships = { Relationships: [] };

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: Partial<Profile> & { id: string; name: string; email: string };
        Update: Partial<Profile>;
      } & NoRelationships;
      courses: { Row: Course; Insert: Partial<Course>; Update: Partial<Course> } & NoRelationships;
      lessons: { Row: Lesson; Insert: Partial<Lesson>; Update: Partial<Lesson> } & NoRelationships;
      quiz_questions: {
        Row: QuizQuestion;
        Insert: Partial<QuizQuestion>;
        Update: Partial<QuizQuestion>;
      } & NoRelationships;
      lesson_progress: {
        Row: LessonProgress;
        Insert: Partial<LessonProgress>;
        Update: Partial<LessonProgress>;
      } & NoRelationships;
      projects: { Row: Project; Insert: Partial<Project>; Update: Partial<Project> } & NoRelationships;
      subscriptions: {
        Row: Subscription;
        Insert: Partial<Subscription>;
        Update: Partial<Subscription>;
      } & NoRelationships;
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
  };
};
