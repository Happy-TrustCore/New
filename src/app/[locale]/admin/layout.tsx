import { redirect } from "@/i18n/navigation";
import { getLocale } from "next-intl/server";
import { createClient } from "@/lib/supabase/server";
import { AdminSidebar } from "@/components/admin/AdminSidebar";

export default async function AdminLayout({ children }: LayoutProps<"/[locale]/admin">) {
  const locale = await getLocale();
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return redirect({ href: "/login", locale });

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .single();
  if (!profile?.is_admin) return redirect({ href: "/dashboard", locale });

  return (
    <div className="flex min-h-screen flex-col sm:flex-row">
      <AdminSidebar />
      <main className="flex-1 p-4 sm:p-8">{children}</main>
    </div>
  );
}
