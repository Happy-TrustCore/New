import { type NextRequest } from "next/server";
import createIntlMiddleware from "next-intl/middleware";
import { routing } from "@/i18n/routing";
import { updateSession } from "@/lib/supabase/proxy";

const handleIntl = createIntlMiddleware(routing);

export async function proxy(request: NextRequest) {
  const intlResponse = handleIntl(request);
  return updateSession(request, intlResponse);
}

export const config = {
  matcher: [
    // "api" is excluded so webhook routes (e.g. Stripe) reach the handler
    // untouched — no locale redirect, no auth-cookie rewriting on a request
    // that has neither locale context nor a browser session.
    "/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
