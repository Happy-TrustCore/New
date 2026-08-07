import Link from "next/link";
import { signIn } from "@/lib/actions/auth";

export default async function LoginPage({
  searchParams,
}: PageProps<"/login">) {
  const params = await searchParams;
  const error = typeof params.error === "string" ? params.error : null;
  const notice = typeof params.notice === "string" ? params.notice : null;
  const next = typeof params.next === "string" ? params.next : "/dashboard";

  return (
    <main className="flex flex-1 items-center justify-center px-6 py-16">
      <div className="w-full max-w-sm">
        <Link href="/" className="font-mono text-sm text-muted">
          &larr; Back home
        </Link>
        <h1 className="mt-4 text-2xl font-bold">Welcome back</h1>
        <p className="mt-1 text-sm text-muted">Continue where you left off.</p>

        {notice && (
          <p className="mt-4 rounded-lg border border-accent/40 bg-accent/10 px-4 py-2 text-sm text-accent">
            {notice}
          </p>
        )}
        {error && (
          <p className="mt-4 rounded-lg border border-red-500/40 bg-red-500/10 px-4 py-2 text-sm text-red-400">
            {error}
          </p>
        )}

        <form action={signIn} className="mt-6 space-y-4">
          <input type="hidden" name="next" value={next} />
          <div>
            <label htmlFor="email" className="text-sm text-muted">
              Email
            </label>
            <input
              id="email"
              name="email"
              type="email"
              required
              className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 outline-none focus:border-accent"
            />
          </div>
          <div>
            <label htmlFor="password" className="text-sm text-muted">
              Password
            </label>
            <input
              id="password"
              name="password"
              type="password"
              required
              className="mt-1 w-full rounded-lg border border-border bg-surface px-3 py-2 outline-none focus:border-accent"
            />
          </div>
          <button
            type="submit"
            className="w-full rounded-lg bg-accent py-2.5 font-semibold text-accent-foreground transition hover:opacity-90"
          >
            Log in
          </button>
        </form>

        <p className="mt-6 text-center text-sm text-muted">
          New here?{" "}
          <Link href="/register" className="text-accent">
            Start learning free
          </Link>
        </p>
      </div>
    </main>
  );
}
