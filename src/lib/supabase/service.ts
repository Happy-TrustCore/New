import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/types";

// Service-role client: bypasses RLS entirely. Only ever use this from
// trusted server-only code that has already verified its own authorization
// some other way — the Stripe webhook handler verifies the request came
// from Stripe (signature check) instead of a user session, since webhook
// requests carry no cookies/JWT to check RLS against in the first place.
export function createServiceClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) {
    throw new Error("SUPABASE_SERVICE_ROLE_KEY is not configured.");
  }
  return createClient<Database>(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
