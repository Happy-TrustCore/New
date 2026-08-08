import { createClient } from "@/lib/supabase/server";

export default async function AdminOverviewPage() {
  const supabase = await createClient();
  const [
    { count: userCount },
    { count: lessonCount },
    { count: completionCount },
    { count: premiumCount },
  ] = await Promise.all([
    supabase.from("profiles").select("id", { count: "exact", head: true }),
    supabase.from("lessons").select("id", { count: "exact", head: true }),
    supabase
      .from("lesson_progress")
      .select("id", { count: "exact", head: true })
      .eq("status", "completed"),
    supabase.from("profiles").select("id", { count: "exact", head: true }).eq("account_type", "premium"),
  ]);

  const stats = [
    { label: "Students", value: userCount ?? 0, color: "text-accent" },
    { label: "Lessons published", value: lessonCount ?? 0, color: "text-accent-2" },
    { label: "Lessons completed", value: completionCount ?? 0, color: "text-accent-3" },
    { label: "Pro subscribers", value: premiumCount ?? 0, color: "text-accent-warm" },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold">Overview</h1>
      <div className="mt-6 grid gap-4 sm:grid-cols-4">
        {stats.map((s) => (
          <div key={s.label} className="card card-hover p-5">
            <p className={`text-2xl font-bold ${s.color}`}>{s.value}</p>
            <p className="mt-1 text-sm text-muted">{s.label}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
