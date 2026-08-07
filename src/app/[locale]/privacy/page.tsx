import { setRequestLocale } from "next-intl/server";
import { useLocale } from "next-intl";
import { Link } from "@/i18n/navigation";
import type { Locale } from "@/i18n/routing";
import { Navbar } from "@/components/marketing/Navbar";
import { Footer } from "@/components/marketing/Footer";

const content = {
  en: {
    title: "Privacy Policy",
    updated: "Last updated: August 8, 2026",
    sections: [
      {
        heading: "1. Who we are",
        body: `CodePath Academy ("we", "us") operates this website. If you have questions about this policy or your data, contact us at privacy@codepathacademy.example.`,
      },
      {
        heading: "2. What information we collect",
        body: `Account information: your name, email address, and password (your password is never stored in readable form — it is hashed by our authentication provider, Supabase).

Learning data: which lessons you've completed, your quiz results, your XP and level, and any code you submit as part of a lesson.

Technical data: standard server logs (e.g. IP address, browser type) collected automatically by our hosting provider for security and reliability.

We do not currently collect payment information, because no payment processor is connected to this platform yet. We do not use advertising cookies or third-party tracking/analytics scripts.`,
      },
      {
        heading: "3. Why we collect it",
        body: `We use this information solely to operate the platform: to create and secure your account, save your learning progress, and let you pick up where you left off. We do not sell your data, and we do not use it for advertising.`,
      },
      {
        heading: "4. Legal basis for processing (for users in the EU/EEA)",
        body: `We process your account and learning data because it is necessary to provide the service you signed up for (performance of a contract). Where we are not relying on contract necessity, we rely on your consent, which you may withdraw at any time by deleting your account.`,
      },
      {
        heading: "5. Who we share it with",
        body: `Your data is stored with our database provider, Supabase, and our application runs on our hosting provider, Vercel. Both act as data processors on our behalf under their own data processing agreements — we do not share your data with any other third party, and we do not sell it.`,
      },
      {
        heading: "6. Cookies",
        body: `We use only strictly necessary cookies: one to keep you signed in, and one to remember your language preference (English/German). We do not use cookies for advertising or cross-site tracking.`,
      },
      {
        heading: "7. How long we keep your data",
        body: `We keep your account and learning data for as long as your account is active. If you ask us to delete your account, we will delete your personal data within a reasonable time, except where we are required to keep certain records by law.`,
      },
      {
        heading: "8. Your rights",
        body: `If you are located in the EU/EEA (or another jurisdiction with similar protections), you have the right to: access the personal data we hold about you, correct inaccurate data, request deletion of your data, restrict or object to certain processing, receive your data in a portable format, and lodge a complaint with your local data protection authority.

To exercise any of these rights, contact us at the email above.`,
      },
      {
        heading: "9. Children's privacy",
        body: `This platform is not intended for children under 16 without the consent of a parent or guardian.`,
      },
      {
        heading: "10. Changes to this policy",
        body: `We may update this policy as the platform grows (for example, when we add payment processing or an AI mentor feature). We will update the "last updated" date above when we do.`,
      },
      {
        heading: "11. Contact",
        body: `Questions? Email us at privacy@codepathacademy.example.`,
      },
    ],
  },
  de: {
    title: "Datenschutzerklärung",
    updated: "Zuletzt aktualisiert: 8. August 2026",
    sections: [
      {
        heading: "1. Wer wir sind",
        body: `CodePath Academy („wir“, „uns“) betreibt diese Website. Bei Fragen zu dieser Erklärung oder deinen Daten kontaktiere uns unter privacy@codepathacademy.example.`,
      },
      {
        heading: "2. Welche Daten wir erheben",
        body: `Kontoinformationen: dein Name, deine E-Mail-Adresse und dein Passwort (dein Passwort wird niemals im Klartext gespeichert — es wird von unserem Authentifizierungsanbieter Supabase gehasht).

Lerndaten: welche Lektionen du abgeschlossen hast, deine Quiz-Ergebnisse, dein XP-Stand und dein Level sowie jeglicher Code, den du im Rahmen einer Lektion einreichst.

Technische Daten: übliche Server-Protokolle (z. B. IP-Adresse, Browsertyp), die automatisch von unserem Hosting-Anbieter zur Sicherheit und Zuverlässigkeit erfasst werden.

Wir erheben derzeit keine Zahlungsinformationen, da noch kein Zahlungsdienstleister an diese Plattform angebunden ist. Wir verwenden keine Werbe-Cookies und keine Tracking- oder Analyse-Skripte von Drittanbietern.`,
      },
      {
        heading: "3. Warum wir sie erheben",
        body: `Wir nutzen diese Informationen ausschließlich zum Betrieb der Plattform: um dein Konto zu erstellen und zu sichern, deinen Lernfortschritt zu speichern und dir zu ermöglichen, dort weiterzumachen, wo du aufgehört hast. Wir verkaufen deine Daten nicht und nutzen sie nicht für Werbung.`,
      },
      {
        heading: "4. Rechtsgrundlage der Verarbeitung (für Nutzer in der EU/im EWR)",
        body: `Wir verarbeiten deine Konto- und Lerndaten, weil dies zur Erbringung der Dienstleistung, für die du dich angemeldet hast, erforderlich ist (Vertragserfüllung). Soweit wir uns nicht auf die Vertragserfüllung stützen, beruht die Verarbeitung auf deiner Einwilligung, die du jederzeit durch Löschung deines Kontos widerrufen kannst.`,
      },
      {
        heading: "5. Mit wem wir sie teilen",
        body: `Deine Daten werden bei unserem Datenbankanbieter Supabase gespeichert, und unsere Anwendung läuft bei unserem Hosting-Anbieter Vercel. Beide handeln in unserem Auftrag als Auftragsverarbeiter im Rahmen eigener Auftragsverarbeitungsverträge — wir geben deine Daten an keine weiteren Dritten weiter und verkaufen sie nicht.`,
      },
      {
        heading: "6. Cookies",
        body: `Wir verwenden ausschließlich technisch notwendige Cookies: eines, um dich angemeldet zu halten, und eines, um deine Sprachpräferenz (Englisch/Deutsch) zu speichern. Wir verwenden keine Cookies für Werbung oder seitenübergreifendes Tracking.`,
      },
      {
        heading: "7. Wie lange wir deine Daten speichern",
        body: `Wir speichern deine Konto- und Lerndaten, solange dein Konto aktiv ist. Wenn du die Löschung deines Kontos beantragst, löschen wir deine personenbezogenen Daten innerhalb einer angemessenen Frist, außer soweit wir gesetzlich zur Aufbewahrung bestimmter Aufzeichnungen verpflichtet sind.`,
      },
      {
        heading: "8. Deine Rechte",
        body: `Wenn du dich in der EU/im EWR (oder einer anderen Rechtsordnung mit vergleichbarem Schutz) befindest, hast du das Recht: Auskunft über die von uns über dich gespeicherten personenbezogenen Daten zu erhalten, unrichtige Daten berichtigen zu lassen, die Löschung deiner Daten zu verlangen, bestimmte Verarbeitungen einzuschränken oder ihnen zu widersprechen, deine Daten in einem übertragbaren Format zu erhalten, und Beschwerde bei deiner örtlichen Datenschutzbehörde einzulegen.

Um eines dieser Rechte auszuüben, kontaktiere uns unter der oben genannten E-Mail-Adresse.`,
      },
      {
        heading: "9. Datenschutz für Kinder",
        body: `Diese Plattform ist nicht für Kinder unter 16 Jahren ohne Zustimmung eines Elternteils oder Erziehungsberechtigten vorgesehen.`,
      },
      {
        heading: "10. Änderungen dieser Erklärung",
        body: `Wir können diese Erklärung aktualisieren, wenn die Plattform wächst (zum Beispiel, wenn wir eine Zahlungsabwicklung oder eine KI-Mentor-Funktion hinzufügen). Das Datum „Zuletzt aktualisiert“ oben wird dann entsprechend angepasst.`,
      },
      {
        heading: "11. Kontakt",
        body: `Fragen? Schreib uns an privacy@codepathacademy.example.`,
      },
    ],
  },
};

export default async function PrivacyPage({
  params,
}: PageProps<"/[locale]/privacy">) {
  const { locale } = (await params) as { locale: Locale };
  setRequestLocale(locale);
  return <PrivacyContent />;
}

function PrivacyContent() {
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
