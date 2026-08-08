import { createClient } from "@/lib/supabase/server";
import { createRealProject, deleteRealProject, setRealProjectStatus } from "@/lib/actions/admin";
import type { RealProjectStatus, SkillTrack } from "@/lib/supabase/types";

const SKILL_TRACKS: SkillTrack[] = ["frontend", "backend", "fullstack"];

export default async function AdminMarketplacePage() {
  const supabase = await createClient();
  const [{ data: projects }, { data: interests }, { data: profiles }] = await Promise.all([
    supabase.from("real_projects").select("*").order("sort_order"),
    supabase.from("project_interests").select("*"),
    supabase.from("profiles").select("id, name, email"),
  ]);

  const profileById = new Map((profiles ?? []).map((p) => [p.id, p]));

  return (
    <div>
      <h1 className="text-2xl font-bold">Real Project Marketplace</h1>
      <p className="mt-1 text-sm text-muted">
        Freelance-style opportunities offered to Pro students. No payment/contract flow yet —
        follow up manually with anyone who expresses interest below.
      </p>

      <form
        action={createRealProject}
        className="mt-6 grid gap-4 rounded-xl border border-border bg-surface p-6 sm:grid-cols-2"
      >
        <label className="block">
          <span className="text-sm text-muted">Title (English)</span>
          <input
            name="title_en"
            required
            className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm text-muted">Title (German)</span>
          <input
            name="title_de"
            required
            className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2"
          />
        </label>
        <label className="block sm:col-span-2">
          <span className="text-sm text-muted">Description (English)</span>
          <textarea
            name="description_en"
            required
            rows={3}
            className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2"
          />
        </label>
        <label className="block sm:col-span-2">
          <span className="text-sm text-muted">Description (German)</span>
          <textarea
            name="description_de"
            required
            rows={3}
            className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2"
          />
        </label>
        <label className="block">
          <span className="text-sm text-muted">Skill track</span>
          <select
            name="skill_track"
            className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2"
          >
            {SKILL_TRACKS.map((track) => (
              <option key={track} value={track}>
                {track}
              </option>
            ))}
          </select>
        </label>
        <label className="block">
          <span className="text-sm text-muted">Client name (optional)</span>
          <input
            name="client_name"
            className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2"
          />
        </label>
        <button
          type="submit"
          className="btn-primary rounded-lg px-4 py-2 text-sm sm:col-span-2 sm:w-fit"
        >
          + Add project
        </button>
      </form>

      <div className="mt-8 space-y-4">
        {(projects ?? []).map((project) => {
          const projectInterests = (interests ?? []).filter(
            (i) => i.real_project_id === project.id
          );
          return (
            <div key={project.id} className="rounded-xl border border-border bg-surface p-5">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <span className="pill px-2 py-0.5 text-xs font-mono text-accent">
                    {project.skill_track}
                  </span>
                  <span
                    className={`ml-2 rounded-full px-2 py-0.5 text-xs ${
                      project.status === "open"
                        ? "bg-accent/10 text-accent"
                        : "bg-surface-2 text-muted"
                    }`}
                  >
                    {project.status}
                  </span>
                  <h2 className="mt-2 text-lg font-semibold">{project.title.en}</h2>
                  <p className="mt-1 text-sm text-muted">{project.description.en}</p>
                </div>
                <div className="flex shrink-0 gap-2">
                  <form
                    action={setRealProjectStatus.bind(
                      null,
                      project.id,
                      (project.status === "open" ? "closed" : "open") as RealProjectStatus
                    )}
                  >
                    <button
                      type="submit"
                      className="rounded-lg border border-border px-3 py-1.5 text-xs hover:bg-surface-2"
                    >
                      Mark {project.status === "open" ? "closed" : "open"}
                    </button>
                  </form>
                  <form action={deleteRealProject.bind(null, project.id)}>
                    <button
                      type="submit"
                      className="rounded-lg border border-danger/50 px-3 py-1.5 text-xs text-danger hover:bg-danger/10"
                    >
                      Delete
                    </button>
                  </form>
                </div>
              </div>

              <div className="mt-4 border-t border-border pt-3">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted">
                  Interested ({projectInterests.length})
                </p>
                {projectInterests.length === 0 ? (
                  <p className="mt-1 text-xs text-muted">No one yet.</p>
                ) : (
                  <ul className="mt-2 space-y-2">
                    {projectInterests.map((interest) => {
                      const student = profileById.get(interest.user_id);
                      return (
                        <li key={interest.id} className="text-sm">
                          <span className="font-semibold">{student?.name ?? "Unknown"}</span>{" "}
                          <span className="text-muted">{student?.email}</span>
                          {interest.message && (
                            <p className="mt-0.5 text-xs text-muted">
                              &ldquo;{interest.message}&rdquo;
                            </p>
                          )}
                        </li>
                      );
                    })}
                  </ul>
                )}
              </div>
            </div>
          );
        })}
        {(projects ?? []).length === 0 && (
          <p className="text-sm text-muted">No projects yet — add one above.</p>
        )}
      </div>
    </div>
  );
}
