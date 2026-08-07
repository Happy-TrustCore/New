export function Footer() {
  return (
    <footer className="border-t border-border py-10">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 text-sm text-muted sm:flex-row">
        <p className="font-mono">
          &lt;/&gt; CodePath<span className="text-gradient">Academy</span>
        </p>
        <p>Start from zero. Build real things. Become a developer.</p>
        <p>&copy; {new Date().getFullYear()} CodePath Academy</p>
      </div>
    </footer>
  );
}
