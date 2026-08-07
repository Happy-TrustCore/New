import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { routing } from "@/i18n/routing";

const PROTECTED_SECTIONS = ["dashboard", "learn", "admin"];

export async function updateSession(request: NextRequest, response: NextResponse) {
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  // With localePrefix "as-needed", the default locale (en) has no URL
  // prefix, so the protected "section" is either the first or second
  // path segment depending on whether a locale prefix is present.
  const segments = request.nextUrl.pathname.split("/").filter(Boolean);
  const hasLocalePrefix = (routing.locales as readonly string[]).includes(segments[0]);
  const currentLocale = hasLocalePrefix ? segments[0] : routing.defaultLocale;
  const section = hasLocalePrefix ? segments[1] : segments[0];

  if (PROTECTED_SECTIONS.includes(section) && !user) {
    const loginPath =
      currentLocale === routing.defaultLocale ? "/login" : `/${currentLocale}/login`;
    const redirectUrl = new URL(loginPath, request.url);
    redirectUrl.searchParams.set("next", request.nextUrl.pathname);
    return NextResponse.redirect(redirectUrl);
  }

  return response;
}
