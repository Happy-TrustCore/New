import { notFound } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { createClient } from "@/lib/supabase/server";
import { pickLocale } from "@/lib/i18n-content";
import { Navbar } from "@/components/marketing/Navbar";
import { Footer } from "@/components/marketing/Footer";

export default async function CertificatePage({
  params,
}: PageProps<"/[locale]/certificate/[id]">) {
  const { locale, id } = (await params) as { locale: Locale; id: string };
  setRequestLocale(locale);
  const t = await getTranslations("certificate");

  const supabase = await createClient();
  const { data: certificate } = await supabase
    .from("certificates")
    .select("*")
    .eq("id", id)
    .maybeSingle();

  if (!certificate) {
    notFound();
  }

  const { data: course } = await supabase
    .from("courses")
    .select("*")
    .eq("id", certificate.course_id)
    .single();

  const issuedDate = new Date(certificate.issued_at).toLocaleDateString(locale, {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  return (
    <>
      <Navbar />
      <main className="flex flex-1 items-center justify-center px-6 py-16">
        <div className="glow-accent card w-full max-w-2xl p-10 text-center sm:p-14">
          <p className="font-mono text-xs uppercase tracking-[0.2em] text-accent">
            {t("eyebrow")}
          </p>
          <h1 className="mt-4 text-3xl font-bold sm:text-4xl">{t("title")}</h1>
          <p className="mt-8 text-sm text-muted">{t("issuedTo")}</p>
          <p className="text-gradient mt-1 text-3xl font-bold sm:text-4xl">
            {certificate.student_name}
          </p>
          <p className="mt-6 text-sm text-muted">{t("forCompleting")}</p>
          <p className="mt-1 text-xl font-semibold">
            {course ? pickLocale(course.title, locale) : ""}
          </p>
          <p className="mt-8 font-mono text-xs text-muted">
            {t("issuedOn", { date: issuedDate })}
          </p>
          <div className="mx-auto mt-8 h-px w-24 bg-border" />
          <p className="mt-6 font-mono text-sm font-semibold">
            <span className="text-accent">&lt;/&gt;</span> CodePath
            <span className="text-gradient">Academy</span>
          </p>
        </div>
      </main>
      <div className="pb-8 text-center">
        <Link href="/" className="text-sm text-muted hover:text-foreground">
          {t("backHome")} &rarr;
        </Link>
      </div>
      <Footer />
    </>
  );
}
