export type BadgeId =
  | "foundation-complete"
  | "first-website"
  | "css-designer"
  | "frontend-graduate"
  | "backend-explorer"
  | "backend-graduate"
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
  { id: "foundation-complete", icon: "🎯", requiredSlugs: ["how-programming-works", "how-websites-work"] },
  { id: "first-website", icon: "🏆", requiredSlugs: ["html-hello-world"] },
  { id: "css-designer", icon: "🎨", requiredSlugs: ["css-styling-basics"] },
  { id: "frontend-graduate", icon: "🖥️", requiredSlugs: ["frontend-free-exam"] },
  { id: "backend-explorer", icon: "🔌", requiredSlugs: ["creating-your-first-server"] },
  { id: "backend-graduate", icon: "🛠️", requiredSlugs: ["backend-free-exam"] },
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
