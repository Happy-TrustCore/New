import { getTranslations } from "next-intl/server";
import { redirect } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";
import { ProfileForm } from "@/components/settings/ProfileForm";
import { PasswordForm } from "@/components/settings/PasswordForm";
import { DeleteAccountForm } from "@/components/settings/DeleteAccountForm";

export default async function SettingsPage({
  params,
}: PageProps<"/[locale]/settings">) {
  const { locale } = (await params) as { locale: Locale };
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return redirect({ href: "/login", locale });

  const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).single();
  const t = await getTranslations("settings");

  return (
    <div className="mx-auto max-w-2xl px-6 py-10">
      <h1 className="text-2xl font-bold">{t("title")}</h1>
      <p className="mt-1 text-sm text-muted">{user.email}</p>

      <div className="mt-8">
        <ProfileForm currentName={profile?.name ?? ""} />
        <PasswordForm />
        <DeleteAccountForm />
      </div>
    </div>
  );
}
