import { getTranslations } from "next-intl/server";
import { redirect } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";
import { hasPremiumAccess } from "@/lib/lessons";
import { pickLocale } from "@/lib/i18n-content";
import { InterestButton } from "@/components/marketplace/InterestButton";
import { startCheckout } from "@/lib/actions/billing";

const TRACK_LABEL: Record<string, string> = {
  frontend: "Frontend",
  backend: "Backend",
  fullstack: "Full Stack",
};

export default async function MarketplacePage({
  params,
}: PageProps<"/[locale]/marketplace">) {
  const { locale } = (await params) as { locale: Locale };
  const supabase = await createClient();
  const t = await getTranslations("marketplace");

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return redirect({ href: "/login", locale });

  const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).single();
  const isPremium = hasPremiumAccess(profile);

  if (!isPremium) {
    return (
      <div className="mx-auto flex max-w-xl flex-col items-center gap-4 px-6 py-24 text-center">
        <span className="text-4xl">🚀</span>
        <h1 className="text-2xl font-bold">{t("paywall.title")}</h1>
        <p className="text-muted">{t("paywall.body")}</p>
        <form action={startCheckout}>
          <button type="submit" className="btn-primary rounded-lg px-6 py-3 text-sm">
            {t("paywall.cta")}
          </button>
        </form>
      </div>
    );
  }

  const [{ data: projects }, { data: interests }] = await Promise.all([
    supabase
      .from("real_projects")
      .select("*")
      .eq("status", "open")
      .order("sort_order"),
    supabase.from("project_interests").select("real_project_id").eq("user_id", user.id),
  ]);

  const interestedIds = new Set((interests ?? []).map((i) => i.real_project_id));

  return (
    <div className="mx-auto max-w-4xl px-6 py-10">
      <h1 className="text-2xl font-bold">{t("title")}</h1>
      <p className="mt-1 text-muted">{t("subtitle")}</p>

      {(projects ?? []).length === 0 ? (
        <div className="mt-8 flex flex-col items-center gap-2 rounded-xl border border-border bg-surface px-6 py-16 text-center">
          <span className="text-3xl">📭</span>
          <p className="text-sm text-muted">{t("empty")}</p>
        </div>
      ) : (
        <div className="mt-8 space-y-4">
          {(projects ?? []).map((project) => (
            <div key={project.id} className="card card-hover p-6">
              <div className="flex flex-wrap items-center gap-2">
                <span className="pill px-3 py-1 text-xs font-mono text-accent">
                  {TRACK_LABEL[project.skill_track] ?? project.skill_track}
                </span>
                {project.client_name && (
                  <span className="text-xs text-muted">{project.client_name}</span>
                )}
              </div>
              <h2 className="mt-3 text-lg font-semibold">{pickLocale(project.title, locale)}</h2>
              <p className="mt-2 text-sm text-muted">{pickLocale(project.description, locale)}</p>
              <div className="mt-4">
                <InterestButton
                  projectId={project.id}
                  alreadyInterested={interestedIds.has(project.id)}
                />
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
