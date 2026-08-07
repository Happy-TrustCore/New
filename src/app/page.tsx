import Link from "next/link";
import { Navbar } from "@/components/marketing/Navbar";
import { Footer } from "@/components/marketing/Footer";

const roadmap = [
  {
    step: "01",
    title: "Foundation",
    tagline: "2 short lessons. Understand how code and the web work.",
    tech: ["How programming works", "How websites work"],
    access: "Free",
  },
  {
    step: "02",
    title: "Frontend Development",
    tagline: "HTML grows into CSS, then JavaScript, then React — one project at a time.",
    tech: ["HTML", "CSS", "JavaScript", "React"],
    access: "First 16 lessons free",
  },
  {
    step: "03",
    title: "Backend Development",
    tagline: "Servers, Node.js, databases, and authentication — built the same way.",
    tech: ["Node.js", "Express", "PostgreSQL", "Auth"],
    access: "First 16 lessons free",
  },
];

const method = [
  { label: "Learn", desc: "A new concept, explained simply with a real example." },
  { label: "Use", desc: "Write the code yourself in the built-in editor." },
  { label: "Improve", desc: "Take the same project further, never start over." },
  { label: "Combine", desc: "Bring technologies together into one real result." },
];

export default function Home() {
  return (
    <>
      <Navbar />
      <main className="flex-1">
        {/* Hero */}
        <section className="mx-auto flex max-w-6xl flex-col items-center gap-8 px-6 pb-20 pt-20 text-center sm:pt-28">
          <span className="rounded-full border border-border bg-surface px-4 py-1 text-xs text-muted">
            Foundation is 100% free — no card required
          </span>
          <h1 className="max-w-3xl text-4xl font-bold tracking-tight sm:text-6xl">
            Become a developer by{" "}
            <span className="text-gradient">building</span>, not watching.
          </h1>
          <p className="max-w-2xl text-lg text-muted">
            CodePath Academy takes you from &ldquo;I have never written code&rdquo; to
            shipping real websites and applications — one growing project at a
            time, through Foundation, Frontend, and Backend.
          </p>
          <div className="flex flex-wrap items-center justify-center gap-4">
            <Link
              href="/register"
              className="rounded-lg bg-accent px-6 py-3 font-semibold text-accent-foreground transition hover:opacity-90"
            >
              Start Learning Free
            </Link>
            <a
              href="#roadmap"
              className="rounded-lg border border-border px-6 py-3 font-semibold text-foreground transition hover:bg-surface"
            >
              See the roadmap
            </a>
          </div>

          {/* mock editor */}
          <div className="mt-10 w-full max-w-2xl overflow-hidden rounded-xl border border-border bg-surface text-left shadow-2xl">
            <div className="flex items-center gap-1.5 border-b border-border px-4 py-3">
              <span className="h-3 w-3 rounded-full bg-red-500/70" />
              <span className="h-3 w-3 rounded-full bg-yellow-500/70" />
              <span className="h-3 w-3 rounded-full bg-green-500/70" />
              <span className="ml-3 font-mono text-xs text-muted">lesson-01.html</span>
            </div>
            <pre className="overflow-x-auto p-5 font-mono text-sm leading-relaxed">
              <code>
                <span className="text-muted">{"<h1>"}</span>
                {"Hello, my name is "}
                <span className="text-accent">Ahmed</span>
                <span className="text-muted">{"</h1>"}</span>
                {"\n"}
                <span className="text-muted">{"<p>"}</span>
                {"This is my first website."}
                <span className="text-muted">{"</p>"}</span>
              </code>
            </pre>
          </div>
        </section>

        {/* How it works */}
        <section id="how-it-works" className="border-t border-border bg-surface/40 py-20">
          <div className="mx-auto max-w-6xl px-6">
            <h2 className="text-center text-3xl font-bold">
              The CodePath teaching system
            </h2>
            <p className="mx-auto mt-3 max-w-2xl text-center text-muted">
              Real developers don&rsquo;t learn one language at a time. Every
              technology starts from zero, but what you already know keeps
              growing right alongside it.
            </p>
            <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
              {method.map((m, i) => (
                <div
                  key={m.label}
                  className="rounded-xl border border-border bg-surface p-6"
                >
                  <span className="font-mono text-sm text-accent">
                    0{i + 1}
                  </span>
                  <h3 className="mt-2 text-lg font-semibold">{m.label}</h3>
                  <p className="mt-2 text-sm text-muted">{m.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Roadmap */}
        <section id="roadmap" className="py-20">
          <div className="mx-auto max-w-6xl px-6">
            <h2 className="text-center text-3xl font-bold">Your learning path</h2>
            <p className="mx-auto mt-3 max-w-2xl text-center text-muted">
              Three parts. One growing journey. No skipping ahead.
            </p>
            <div className="mt-12 grid gap-6 lg:grid-cols-3">
              {roadmap.map((r) => (
                <div
                  key={r.step}
                  className="flex flex-col rounded-xl border border-border bg-surface p-6"
                >
                  <span className="font-mono text-sm text-muted">{r.step}</span>
                  <h3 className="mt-2 text-xl font-semibold">{r.title}</h3>
                  <p className="mt-2 text-sm text-muted">{r.tagline}</p>
                  <div className="mt-4 flex flex-wrap gap-2">
                    {r.tech.map((t) => (
                      <span
                        key={t}
                        className="rounded-full border border-border bg-surface-2 px-3 py-1 text-xs font-mono text-foreground"
                      >
                        {t}
                      </span>
                    ))}
                  </div>
                  <span className="mt-6 inline-block w-fit rounded-full bg-accent/10 px-3 py-1 text-xs font-semibold text-accent">
                    {r.access}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Pricing */}
        <section id="pricing" className="border-t border-border bg-surface/40 py-20">
          <div className="mx-auto max-w-4xl px-6">
            <h2 className="text-center text-3xl font-bold">Simple pricing</h2>
            <p className="mx-auto mt-3 max-w-xl text-center text-muted">
              Learn Foundation and the first 16 lessons of Frontend and Backend
              completely free. Upgrade only when you want to keep going.
            </p>
            <div className="mt-12 grid gap-6 sm:grid-cols-2">
              <div className="rounded-xl border border-border bg-surface p-8">
                <h3 className="text-lg font-semibold">Free</h3>
                <p className="mt-1 text-3xl font-bold">€0</p>
                <ul className="mt-6 space-y-3 text-sm text-muted">
                  <li>✓ Full Foundation track</li>
                  <li>✓ 16 free Frontend lessons</li>
                  <li>✓ 16 free Backend lessons</li>
                  <li>✓ Practice, quizzes &amp; progress saved</li>
                </ul>
                <Link
                  href="/register"
                  className="mt-8 block rounded-lg border border-border py-2.5 text-center font-semibold hover:bg-surface-2"
                >
                  Start Free
                </Link>
              </div>
              <div className="rounded-xl border border-accent/60 bg-surface p-8 shadow-[0_0_40px_-15px_var(--accent)]">
                <h3 className="text-lg font-semibold text-accent">
                  CodePath Pro
                </h3>
                <p className="mt-1 text-3xl font-bold">
                  €4.99<span className="text-base font-normal text-muted">/mo</span>
                </p>
                <ul className="mt-6 space-y-3 text-sm text-muted">
                  <li>✓ All lessons, projects &amp; exams</li>
                  <li>✓ CodeBuddy AI mentor</li>
                  <li>✓ Certificates</li>
                  <li>✓ Real client project opportunities</li>
                </ul>
                <Link
                  href="/register"
                  className="mt-8 block rounded-lg bg-accent py-2.5 text-center font-semibold text-accent-foreground hover:opacity-90"
                >
                  Go Pro
                </Link>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
