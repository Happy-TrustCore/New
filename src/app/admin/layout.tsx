import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { signOut } from "@/lib/actions/auth";

export default async function AdminLayout({ children }: LayoutProps<"/admin">) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .single();
  if (!profile?.is_admin) redirect("/dashboard");

  return (
    <div className="flex min-h-screen">
      <aside className="w-56 shrink-0 border-r border-border bg-surface/60 p-4">
        <Link href="/dashboard" className="font-mono text-sm font-semibold">
          <span className="text-accent">&lt;/&gt;</span> CodePath
          <span className="text-gradient">Academy</span>
        </Link>
        <p className="mt-1 text-xs text-muted">Admin panel</p>
        <nav className="mt-6 space-y-1 text-sm">
          <Link href="/admin" className="block rounded-lg px-3 py-2 hover:bg-surface-2">
            Overview
          </Link>
          <Link href="/admin/lessons" className="block rounded-lg px-3 py-2 hover:bg-surface-2">
            Lessons
          </Link>
          <Link href="/admin/users" className="block rounded-lg px-3 py-2 hover:bg-surface-2">
            Users
          </Link>
        </nav>
        <Link href="/dashboard" className="mt-6 block text-sm text-muted hover:text-foreground">
          &larr; Back to app
        </Link>
        <form action={signOut} className="mt-2">
          <button type="submit" className="text-sm text-muted hover:text-foreground">
            Log out
          </button>
        </form>
      </aside>
      <main className="flex-1 p-8">{children}</main>
    </div>
  );
}
