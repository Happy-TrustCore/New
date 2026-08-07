import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { signOut } from "@/lib/actions/auth";

export default async function LearnLayout({
  children,
}: LayoutProps<"/learn">) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: profile } = user
    ? await supabase.from("profiles").select("xp, level").eq("id", user.id).single()
    : { data: null };

  return (
    <div className="flex h-screen flex-col overflow-hidden">
      <header className="flex shrink-0 items-center justify-between border-b border-border bg-surface/60 px-4 py-2.5">
        <Link href="/dashboard" className="font-mono text-sm font-semibold">
          <span className="text-accent">&lt;/&gt;</span> CodePath
          <span className="text-gradient">Academy</span>
        </Link>
        <div className="flex items-center gap-4">
          <span className="rounded-full border border-border bg-surface-2 px-3 py-1 text-xs font-mono text-muted">
            Level {profile?.level ?? 1} · {profile?.xp ?? 0} XP
          </span>
          <Link href="/dashboard" className="text-sm text-muted hover:text-foreground">
            Dashboard
          </Link>
          <form action={signOut}>
            <button type="submit" className="text-sm text-muted hover:text-foreground">
              Log out
            </button>
          </form>
        </div>
      </header>
      <main className="min-h-0 flex-1">{children}</main>
    </div>
  );
}
