/**
 * Computes the next streak state when a student completes a lesson today.
 * Dates are plain YYYY-MM-DD strings (UTC) — Postgres `date` columns come
 * back from Supabase in this form already, so no timezone parsing needed.
 *
 * - Same day as last activity: no change, already counted today.
 * - Exactly one day after last activity: streak continues (+1).
 * - Any bigger gap (or no prior activity): streak resets to 1.
 */
export function computeStreakUpdate(
  lastActivityDate: string | null,
  currentStreak: number,
  longestStreak: number,
  today: Date = new Date()
): { current_streak: number; longest_streak: number; last_activity_date: string } {
  const todayStr = today.toISOString().slice(0, 10);

  if (lastActivityDate === todayStr) {
    return { current_streak: currentStreak, longest_streak: longestStreak, last_activity_date: todayStr };
  }

  const yesterday = new Date(today);
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const yesterdayStr = yesterday.toISOString().slice(0, 10);

  const newStreak = lastActivityDate === yesterdayStr ? currentStreak + 1 : 1;

  return {
    current_streak: newStreak,
    longest_streak: Math.max(longestStreak, newStreak),
    last_activity_date: todayStr,
  };
}
