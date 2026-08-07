import { setRequestLocale } from "next-intl/server";
import { useLocale } from "next-intl";
import { Link } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { Navbar } from "@/components/marketing/Navbar";
import { Footer } from "@/components/marketing/Footer";

const content = {
  en: {
    title: "Terms of Service",
    updated: "Last updated: August 8, 2026",
    sections: [
      {
        heading: "1. Acceptance of these terms",
        body: `By creating an account or using CodePath Academy, you agree to these Terms of Service. If you do not agree, please do not use the platform.`,
      },
      {
        heading: "2. What we offer",
        body: `CodePath Academy is an educational platform that teaches web development through interactive lessons, coding exercises, and quizzes. Some content is free; additional content is planned to require a CodePath Pro subscription in the future. Pricing shown on this site is informational — no payment is currently being processed, and this section will be updated once billing is live.`,
      },
      {
        heading: "3. Your account",
        body: `You're responsible for keeping your password secure and for all activity under your account. You must provide accurate information when registering and you must be old enough to legally use online services in your country (see our Privacy Policy for our children's privacy note).`,
      },
      {
        heading: "4. Acceptable use",
        body: `Please don't: share your account with others, attempt to bypass lesson unlock restrictions, submit harmful or malicious code through the platform, or use the platform to harm others or violate the law.`,
      },
      {
        heading: "5. Course content",
        body: `All lesson content, exercises, and platform design are the property of CodePath Academy. You may not copy, redistribute, or resell course content without permission. Code you personally write while completing exercises is yours.`,
      },
      {
        heading: "6. No guarantee of outcomes",
        body: `Completing lessons or exams does not guarantee employment, certification recognition by third parties, or any particular career outcome. This is a learning tool, not a job placement service.`,
      },
      {
        heading: "7. Service availability",
        body: `We aim to keep the platform available, but we don't guarantee uninterrupted access. Features may change, be added, or be removed as the platform develops.`,
      },
      {
        heading: "8. Termination",
        body: `We may suspend or terminate accounts that violate these terms. You may stop using the platform and request account deletion at any time.`,
      },
      {
        heading: "9. Disclaimer and limitation of liability",
        body: `The platform is provided "as is" without warranties of any kind. To the extent permitted by law, CodePath Academy is not liable for indirect or consequential damages arising from your use of the platform.`,
      },
      {
        heading: "10. Changes to these terms",
        body: `We may update these terms as the platform grows. Continued use after changes means you accept the updated terms.`,
      },
      {
        heading: "11. Contact",
        body: `Questions about these terms? Email us at legal@codepathacademy.example.`,
      },
    ],
  },
  de: {
    title: "Nutzungsbedingungen",
    updated: "Zuletzt aktualisiert: 8. August 2026",
    sections: [
      {
        heading: "1. Annahme dieser Bedingungen",
        body: `Mit der Erstellung eines Kontos oder der Nutzung von CodePath Academy stimmst du diesen Nutzungsbedingungen zu. Wenn du nicht einverstanden bist, nutze die Plattform bitte nicht.`,
      },
      {
        heading: "2. Was wir anbieten",
        body: `CodePath Academy ist eine Lernplattform, die Webentwicklung durch interaktive Lektionen, Programmierübungen und Quizze vermittelt. Manche Inhalte sind kostenlos; für weitere Inhalte ist künftig ein CodePath-Pro-Abonnement vorgesehen. Die auf dieser Seite angezeigten Preise dienen zur Information — derzeit wird keine Zahlung verarbeitet, dieser Abschnitt wird aktualisiert, sobald die Abrechnung live ist.`,
      },
      {
        heading: "3. Dein Konto",
        body: `Du bist dafür verantwortlich, dein Passwort sicher zu verwahren, sowie für alle Aktivitäten unter deinem Konto. Du musst bei der Registrierung wahrheitsgemäße Angaben machen und alt genug sein, um Online-Dienste in deinem Land rechtmäßig zu nutzen (siehe unseren Hinweis zum Datenschutz für Kinder in der Datenschutzerklärung).`,
      },
      {
        heading: "4. Zulässige Nutzung",
        body: `Bitte nicht: dein Konto mit anderen teilen, versuchen, die Freischaltbeschränkungen der Lektionen zu umgehen, schädlichen oder bösartigen Code über die Plattform einreichen, oder die Plattform nutzen, um andere zu schädigen oder gegen Gesetze zu verstoßen.`,
      },
      {
        heading: "5. Kursinhalte",
        body: `Alle Lektionsinhalte, Übungen und das Design der Plattform sind Eigentum von CodePath Academy. Du darfst Kursinhalte ohne Erlaubnis nicht kopieren, weiterverbreiten oder weiterverkaufen. Code, den du selbst beim Bearbeiten von Übungen schreibst, gehört dir.`,
      },
      {
        heading: "6. Keine Erfolgsgarantie",
        body: `Der Abschluss von Lektionen oder Prüfungen garantiert keine Anstellung, keine Anerkennung von Zertifikaten durch Dritte und kein bestimmtes berufliches Ergebnis. Dies ist ein Lernwerkzeug, kein Vermittlungsdienst für Arbeitsplätze.`,
      },
      {
        heading: "7. Verfügbarkeit des Dienstes",
        body: `Wir bemühen uns, die Plattform verfügbar zu halten, garantieren jedoch keinen unterbrechungsfreien Zugang. Funktionen können sich ändern, hinzukommen oder entfallen, während sich die Plattform weiterentwickelt.`,
      },
      {
        heading: "8. Kündigung",
        body: `Wir können Konten sperren oder löschen, die gegen diese Bedingungen verstoßen. Du kannst die Nutzung der Plattform jederzeit beenden und die Löschung deines Kontos beantragen.`,
      },
      {
        heading: "9. Haftungsausschluss und Haftungsbeschränkung",
        body: `Die Plattform wird „wie besehen“ ohne Gewährleistung jeglicher Art bereitgestellt. Soweit gesetzlich zulässig, haftet CodePath Academy nicht für indirekte Schäden oder Folgeschäden, die aus der Nutzung der Plattform entstehen.`,
      },
      {
        heading: "10. Änderungen dieser Bedingungen",
        body: `Wir können diese Bedingungen aktualisieren, wenn die Plattform wächst. Die fortgesetzte Nutzung nach Änderungen bedeutet, dass du die aktualisierten Bedingungen akzeptierst.`,
      },
      {
        heading: "11. Kontakt",
        body: `Fragen zu diesen Bedingungen? Schreib uns an legal@codepathacademy.example.`,
      },
    ],
  },
};

export default async function TermsPage({
  params,
}: PageProps<"/[locale]/terms">) {
  const { locale } = (await params) as { locale: Locale };
  setRequestLocale(locale);
  return <TermsContent />;
}

function TermsContent() {
  const locale = useLocale();
  const page = content[locale];

  return (
    <>
      <Navbar />
      <main className="flex-1">
        <div className="mx-auto max-w-3xl px-6 py-16">
          <Link href="/" className="font-mono text-sm text-muted">
            &larr; {locale === "de" ? "Zurück zur Startseite" : "Back home"}
          </Link>
          <h1 className="mt-4 text-3xl font-bold">{page.title}</h1>
          <p className="mt-1 text-sm text-muted">{page.updated}</p>

          <div className="mt-8 space-y-8">
            {page.sections.map((s) => (
              <section key={s.heading}>
                <h2 className="text-lg font-semibold">{s.heading}</h2>
                <p className="mt-2 whitespace-pre-line leading-relaxed text-muted">{s.body}</p>
              </section>
            ))}
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
