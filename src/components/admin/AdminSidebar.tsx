"use client";

import { useState } from "react";
import { Link, usePathname } from "@/i18n/navigation";
import { signOut } from "@/lib/actions/auth";

const NAV_LINKS = [
  { href: "/admin", label: "Overview", icon: "📊" },
  { href: "/admin/lessons", label: "Lessons", icon: "📚" },
  { href: "/admin/users", label: "Users", icon: "👤" },
  { href: "/admin/marketplace", label: "Marketplace", icon: "💼" },
] as const;

export function AdminSidebar() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const pathname = usePathname();

  const sidebarBody = (
    <>
      <Link href="/dashboard" className="font-mono text-sm font-semibold transition hover:opacity-90">
        <span className="text-accent-3">&lt;/&gt;</span> CodePath
        <span className="text-gradient">Academy</span>
      </Link>
      <p className="mt-1 text-xs text-muted">Admin panel</p>
      <nav className="mt-6 space-y-1 text-sm">
        {NAV_LINKS.map((link) => {
          const isActive = link.href === "/admin" ? pathname === "/admin" : pathname.startsWith(link.href);
          return (
            <Link
              key={link.href}
              href={link.href}
              onClick={() => setMobileOpen(false)}
              className={`flex items-center gap-2 rounded-lg px-3 py-2 transition ${
                isActive ? "bg-accent/10 font-semibold text-accent" : "hover:bg-surface-2"
              }`}
            >
              <span>{link.icon}</span>
              {link.label}
            </Link>
          );
        })}
      </nav>
      <Link href="/dashboard" className="mt-6 block text-sm text-muted hover:text-foreground">
        &larr; Back to app
      </Link>
      <form action={signOut} className="mt-2">
        <button type="submit" className="text-sm text-muted hover:text-foreground">
          Log out
        </button>
      </form>
    </>
  );

  return (
    <>
      {/* mobile: slim toggle bar instead of the full sidebar eating the width */}
      <div className="flex items-center justify-between border-b border-border bg-surface/60 px-4 py-2.5 backdrop-blur-xl sm:hidden">
        <button onClick={() => setMobileOpen(true)} className="flex items-center gap-2 text-sm font-semibold">
          <span>☰</span> Admin
        </button>
        <Link href="/dashboard" className="text-xs text-muted hover:text-foreground">
          Back to app
        </Link>
      </div>

      {/* desktop: fixed sidebar column, as before */}
      <aside className="hidden w-56 shrink-0 border-r border-border bg-surface/60 p-4 backdrop-blur-xl sm:block">
        {sidebarBody}
      </aside>

      {/* mobile: drawer overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 flex sm:hidden">
          <div className="absolute inset-0 bg-black/60" onClick={() => setMobileOpen(false)} />
          <div className="relative flex h-full w-64 max-w-[85vw] flex-col overflow-y-auto bg-background p-4 shadow-2xl">
            <button
              onClick={() => setMobileOpen(false)}
              className="absolute right-3 top-3 rounded-lg px-2 py-1 text-muted hover:bg-surface-2 hover:text-foreground"
            >
              ✕
            </button>
            {sidebarBody}
          </div>
        </div>
      )}
    </>
  );
}
