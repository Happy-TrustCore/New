import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { signOut } from "@/lib/actions/auth";

export default async function DashboardLayout({
  children,
}: LayoutProps<"/dashboard">) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: profile } = user
    ? await supabase.from("profiles").select("xp, level").eq("id", user.id).single()
    : { data: null };

  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-b border-border bg-surface/60">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <Link href="/" className="font-mono text-lg font-semibold">
            <span className="text-accent">&lt;/&gt;</span> CodePath
            <span className="text-gradient">Academy</span>
          </Link>
          <div className="flex items-center gap-4">
            <span className="rounded-full border border-border bg-surface-2 px-3 py-1 text-xs font-mono text-muted">
              Level {profile?.level ?? 1} · {profile?.xp ?? 0} XP
            </span>
            <form action={signOut}>
              <button
                type="submit"
                className="text-sm text-muted hover:text-foreground"
              >
                Log out
              </button>
            </form>
          </div>
        </div>
      </header>
      <main className="flex-1">{children}</main>
    </div>
  );
}
