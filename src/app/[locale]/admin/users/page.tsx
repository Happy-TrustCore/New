import { createClient } from "@/lib/supabase/server";
import { setAccountType } from "@/lib/actions/admin";
import type { AccountType } from "@/lib/supabase/types";

const PLANS: AccountType[] = ["free", "premium", "student"];

export default async function AdminUsersPage() {
  const supabase = await createClient();
  const { data: profiles } = await supabase
    .from("profiles")
    .select("*")
    .order("created_at", { ascending: false });

  return (
    <div>
      <h1 className="text-2xl font-bold">Users</h1>
      <p className="mt-1 text-sm text-muted">
        No payment system is wired up yet — use this to manually grant Pro access.
      </p>
      <div className="mt-6 overflow-x-auto rounded-xl border border-border bg-surface">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-border text-xs uppercase text-muted">
            <tr>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3">Email</th>
              <th className="px-4 py-3">Plan</th>
              <th className="px-4 py-3">XP</th>
              <th className="px-4 py-3">Joined</th>
              <th className="px-4 py-3">Grant</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {(profiles ?? []).map((p) => (
              <tr key={p.id}>
                <td className="px-4 py-3">
                  {p.name}
                  {p.is_admin ? " (admin)" : ""}
                </td>
                <td className="px-4 py-3 text-muted">{p.email}</td>
                <td className="px-4 py-3 capitalize">{p.account_type}</td>
                <td className="px-4 py-3">{p.xp}</td>
                <td className="px-4 py-3 text-muted">
                  {new Date(p.created_at).toLocaleDateString()}
                </td>
                <td className="px-4 py-3">
                  <div className="flex gap-2">
                    {PLANS.map((plan) => (
                      <form key={plan} action={setAccountType.bind(null, p.id, plan)}>
                        <button
                          type="submit"
                          disabled={p.account_type === plan}
                          className={`rounded-md px-2 py-1 text-xs capitalize ${
                            p.account_type === plan
                              ? "bg-accent/20 text-accent"
                              : "border border-border hover:bg-surface-2"
                          }`}
                        >
                          {plan}
                        </button>
                      </form>
                    ))}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
