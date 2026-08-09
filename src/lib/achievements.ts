export type BadgeId =
  | "foundation-complete"
  | "first-website"
  | "css-designer"
  | "frontend-graduate"
  | "javascript-builder"
  | "backend-explorer"
  | "backend-graduate"
  | "backend-engineer"
  | "full-stack-foundations";

export type Badge = {
  id: BadgeId;
  icon: string;
  requiredSlugs: string[];
};

// Badge unlock criteria are expressed as lesson slugs that must all be
// completed — deliberately not stored in the DB, since they're derived
// entirely from lesson_progress and recomputing is cheap and always
// consistent with the current curriculum.
export const BADGES: Badge[] = [
  {
    id: "foundation-complete",
    icon: "🎯",
    requiredSlugs: [
      "how-programming-works",
      "how-websites-work",
      "foundation-programming-languages",
      "foundation-your-toolkit",
      "foundation-your-roadmap",
    ],
  },
  { id: "first-website", icon: "🏆", requiredSlugs: ["html-hello-world"] },
  { id: "css-designer", icon: "🎨", requiredSlugs: ["css-styling-basics"] },
  { id: "frontend-graduate", icon: "🖥️", requiredSlugs: ["frontend-free-exam"] },
  { id: "javascript-builder", icon: "⚡", requiredSlugs: ["js-calculator-project"] },
  { id: "backend-explorer", icon: "🔌", requiredSlugs: ["creating-your-first-server"] },
  { id: "backend-graduate", icon: "🛠️", requiredSlugs: ["backend-free-exam"] },
  { id: "backend-engineer", icon: "🔧", requiredSlugs: ["backend-paid-exam"] },
  {
    id: "full-stack-foundations",
    icon: "🚀",
    requiredSlugs: ["frontend-free-exam", "backend-free-exam"],
  },
];

export function computeBadgeStatus(completedSlugs: Set<string>) {
  return BADGES.map((badge) => ({
    badge,
    earned: badge.requiredSlugs.every((slug) => completedSlugs.has(slug)),
  }));
}
