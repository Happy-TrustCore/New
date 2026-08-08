import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";
import { LocaleSwitcher } from "@/components/LocaleSwitcher";
import { createClient } from "@/lib/supabase/server";
import { signOut } from "@/lib/actions/auth";

export default async function LearnLayout({
  children,
}: LayoutProps<"/[locale]/learn">) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: profile } = user
    ? await supabase.from("profiles").select("xp, level").eq("id", user.id).single()
    : { data: null };

  return <LearnChrome profile={profile}>{children}</LearnChrome>;
}

function LearnChrome({
  profile,
  children,
}: {
  profile: { xp: number; level: number } | null;
  children: React.ReactNode;
}) {
  const t = useTranslations("dashboardChrome");

  return (
    <div className="flex h-screen flex-col overflow-hidden">
      <header className="flex shrink-0 items-center justify-between border-b border-border bg-surface/70 px-4 py-2.5 backdrop-blur-xl">
        <Link href="/dashboard" className="font-mono text-sm font-semibold transition hover:opacity-90">
          <span className="text-accent-3">&lt;/&gt;</span> CodePath
          <span className="text-gradient">Academy</span>
        </Link>
        <div className="flex items-center gap-4">
          <LocaleSwitcher />
          <span className="pill flex items-center gap-1.5 px-3 py-1 text-xs font-mono text-muted">
            <span className="text-accent-warm">⚡</span>
            {t("level")} {profile?.level ?? 1} · {profile?.xp ?? 0} XP
          </span>
          <Link href="/dashboard" className="text-sm text-muted hover:text-foreground">
            {t("dashboard")}
          </Link>
          <Link href="/settings" className="text-sm text-muted hover:text-foreground">
            {t("settings")}
          </Link>
          <form action={signOut}>
            <button type="submit" className="text-sm text-muted hover:text-foreground">
              {t("logout")}
            </button>
          </form>
        </div>
      </header>
      <main className="min-h-0 flex-1">{children}</main>
    </div>
  );
}
