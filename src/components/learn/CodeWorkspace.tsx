"use client";

import { useEffect, useMemo, useState, useTransition } from "react";
import { useTranslations } from "next-intl";
import { useRouter } from "@/i18n/navigation";
import CodeMirror from "@uiw/react-codemirror";
import { vscodeDark } from "@uiw/codemirror-theme-vscode";
import { html } from "@codemirror/lang-html";
import { css } from "@codemirror/lang-css";
import { javascript } from "@codemirror/lang-javascript";
import { submitPractice } from "@/lib/actions/practice";
import { submitAssignment } from "@/lib/actions/assignment";
import { CodeBuddyPanel } from "@/components/learn/CodeBuddyPanel";
import type { StarterCode } from "@/lib/supabase/types";

type Lang = "html" | "css" | "js" | "jsx";

const LANG_DOT: Record<Lang, string> = {
  html: "bg-orange-400",
  css: "bg-sky-400",
  js: "bg-yellow-300",
  jsx: "bg-cyan-400",
};
const LANG_FILE: Record<Lang, string> = {
  html: "index.html",
  css: "style.css",
  js: "script.js",
  jsx: "App.jsx",
};

function getExtensions(lang: Lang) {
  switch (lang) {
    case "html":
      return [html()];
    case "css":
      return [css()];
    case "js":
      return [javascript()];
    case "jsx":
      return [javascript({ jsx: true })];
  }
}

function buildPreviewDoc(code: Record<Lang, string>, enabled: Lang[]) {
  const hasJsx = enabled.includes("jsx");
  const bodyHtml = enabled.includes("html") ? code.html : "";
  const styleTag = enabled.includes("css") ? `<style>${code.css}</style>` : "";
  const scriptTag = enabled.includes("js") ? `<script>${code.js}<\/script>` : "";
  const rootDiv = hasJsx ? '<div id="root"></div>' : "";
  const reactScripts = hasJsx
    ? `<script src="https://unpkg.com/react@18/umd/react.development.js"><\/script>
       <script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"><\/script>
       <script src="https://unpkg.com/@babel/standalone/babel.min.js"><\/script>`
    : "";
  const jsxScript = hasJsx
    ? `<script type="text/babel" data-presets="react">${code.jsx}<\/script>`
    : "";

  const consoleShim = `<script>
    function send(type, args) {
      try {
        parent.postMessage({ source: "codepath-preview", type: type, text: args.map(function (a) {
          try { return typeof a === "string" ? a : JSON.stringify(a); } catch (e) { return String(a); }
        }).join(" ") }, "*");
      } catch (e) {}
    }
    ["log", "warn", "error", "info"].forEach(function (method) {
      var original = console[method];
      console[method] = function () {
        send(method, Array.prototype.slice.call(arguments));
        original.apply(console, arguments);
      };
    });
    window.addEventListener("error", function (e) { send("error", [e.message]); });
  <\/script>`;

  return `<!doctype html><html><head>${consoleShim}${reactScripts}${styleTag}</head><body>${bodyHtml}${rootDiv}${scriptTag}${jsxScript}</body></html>`;
}

export function CodeWorkspace({
  lessonId,
  starterCode,
  practicePassed,
  hasAssignment,
  assignmentPassed,
  isPremium,
}: {
  lessonId: string;
  starterCode: StarterCode | null;
  practicePassed: boolean;
  hasAssignment: boolean;
  assignmentPassed: boolean;
  isPremium: boolean;
}) {
  const router = useRouter();
  const t = useTranslations("learn.editor");
  const [isPending, startTransition] = useTransition();
  const [isSubmittingAssignment, startAssignmentTransition] = useTransition();

  const enabled = useMemo<Lang[]>(() => {
    const langs: Lang[] = [];
    if (starterCode?.html !== undefined) langs.push("html");
    if (starterCode?.css !== undefined) langs.push("css");
    if (starterCode?.js !== undefined) langs.push("js");
    if (starterCode?.jsx !== undefined) langs.push("jsx");
    return langs.length > 0 ? langs : ["html"];
  }, [starterCode]);

  const [code, setCode] = useState<Record<Lang, string>>({
    html: starterCode?.html ?? "<h1>Hello</h1>",
    css: starterCode?.css ?? "",
    js: starterCode?.js ?? "",
    jsx: starterCode?.jsx ?? "",
  });
  const [activeTab, setActiveTab] = useState<Lang>(enabled[0]);
  const [srcDoc, setSrcDoc] = useState(() => buildPreviewDoc(code, enabled));
  const [consoleLines, setConsoleLines] = useState<{ type: string; text: string }[]>([]);
  const [saveState, setSaveState] = useState<"idle" | "done" | "error">(
    practicePassed ? "done" : "idle"
  );
  const [projectTitle, setProjectTitle] = useState("");
  const [assignmentState, setAssignmentState] = useState<"idle" | "done" | "error">(
    assignmentPassed ? "done" : "idle"
  );

  useEffect(() => {
    function handleMessage(event: MessageEvent) {
      if (event.data?.source !== "codepath-preview") return;
      setConsoleLines((lines) => [...lines, { type: event.data.type, text: event.data.text }]);
    }
    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

  useEffect(() => {
    const handle = setTimeout(() => {
      setConsoleLines([]);
      setSrcDoc(buildPreviewDoc(code, enabled));
    }, 500);
    return () => clearTimeout(handle);
  }, [code, enabled]);

  function runCode() {
    setConsoleLines([]);
    setSrcDoc(buildPreviewDoc(code, enabled));
  }

  function handleComplete() {
    startTransition(async () => {
      const result = await submitPractice(lessonId);
      if (!result.ok) {
        setSaveState("error");
        return;
      }
      setSaveState("done");
      router.refresh();
    });
  }

  function handleSubmitAssignment() {
    startAssignmentTransition(async () => {
      const projectCode: StarterCode = {};
      enabled.forEach((lang) => {
        projectCode[lang] = code[lang];
      });
      const result = await submitAssignment(lessonId, projectTitle, projectCode);
      if (!result.ok) {
        setAssignmentState("error");
        return;
      }
      setAssignmentState("done");
      router.refresh();
    });
  }

  return (
    <div className="flex h-full flex-col bg-[#1e1e1e]">
      <div className="flex items-center justify-between border-b border-black/40 bg-[#252526] px-2 py-0">
        <div className="flex gap-0.5">
          {enabled.map((lang) => (
            <button
              key={lang}
              onClick={() => setActiveTab(lang)}
              className={`flex items-center gap-2 border-t-2 px-3 py-2 font-mono text-xs transition ${
                activeTab === lang
                  ? "border-accent-2 bg-[#1e1e1e] text-foreground"
                  : "border-transparent text-muted hover:bg-white/5 hover:text-foreground"
              }`}
            >
              <span className={`h-2 w-2 rounded-full ${LANG_DOT[lang]}`} />
              {LANG_FILE[lang]}
            </button>
          ))}
        </div>
        <button
          onClick={runCode}
          className="btn-primary mr-1 flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs"
        >
          ▶ {t("run")}
        </button>
      </div>

      <div className="min-h-0 flex-[2]">
        <CodeMirror
          value={code[activeTab]}
          height="100%"
          theme={vscodeDark}
          extensions={getExtensions(activeTab)}
          onChange={(value) => setCode((c) => ({ ...c, [activeTab]: value }))}
        />
      </div>

      <div className="flex min-h-0 flex-[2] flex-col border-t border-black/40">
        <div className="flex items-center justify-between border-b border-black/40 bg-[#252526] px-3 py-1.5 text-xs font-mono text-muted">
          <span>{t("preview")}</span>
          <span className="flex items-center gap-1.5 text-accent">
            <span className="animate-pulse-dot h-1.5 w-1.5 rounded-full bg-accent" />
            {t("live")}
          </span>
        </div>
        <iframe
          srcDoc={srcDoc}
          sandbox="allow-scripts"
          title={t("preview")}
          className="min-h-0 flex-1 bg-white"
        />
        <div className="h-24 shrink-0 overflow-y-auto border-t border-black/40 bg-black px-3 py-2 font-mono text-xs">
          {consoleLines.length === 0 ? (
            <p className="text-muted">{t("consolePlaceholder")}</p>
          ) : (
            consoleLines.map((line, i) => (
              <p
                key={i}
                className={
                  line.type === "error"
                    ? "text-red-400"
                    : line.type === "warn"
                    ? "text-yellow-400"
                    : "text-green-400"
                }
              >
                {line.text}
              </p>
            ))
          )}
        </div>
      </div>

      <div className="shrink-0 border-t border-black/40 bg-[#252526] p-3">
        <button
          onClick={handleComplete}
          disabled={isPending || saveState === "done"}
          className="btn-primary w-full rounded-lg py-2 text-sm disabled:opacity-60"
        >
          {isPending ? t("saving") : saveState === "done" ? `✓ ${t("practiceComplete")}` : t("markPracticeComplete")}
        </button>
        {saveState === "error" && (
          <p className="mt-2 text-xs text-danger">{t("saveError")}</p>
        )}
      </div>

      <CodeBuddyPanel
        lessonId={lessonId}
        code={enabled.map((lang) => `// ${lang}\n${code[lang]}`).join("\n\n")}
        isPremium={isPremium}
      />

      {hasAssignment && (
        <div className="shrink-0 border-t border-black/40 bg-[#252526] p-3">
          <p className="mb-2 text-xs font-semibold text-accent">{t("assignmentTitle")}</p>
          {assignmentState === "done" ? (
            <p className="text-sm text-accent">✓ {t("assignmentSubmitted")}</p>
          ) : (
            <>
              <input
                value={projectTitle}
                onChange={(e) => setProjectTitle(e.target.value)}
                placeholder={t("assignmentNamePlaceholder")}
                className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm outline-none focus:border-accent"
              />
              <button
                onClick={handleSubmitAssignment}
                disabled={isSubmittingAssignment || !projectTitle.trim()}
                className="mt-2 w-full rounded-lg border border-accent/60 py-2 text-sm font-semibold text-accent transition hover:bg-accent/10 disabled:opacity-50"
              >
                {isSubmittingAssignment ? t("saving") : t("submitAssignment")}
              </button>
              {assignmentState === "error" && (
                <p className="mt-2 text-xs text-red-400">{t("saveError")}</p>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
}
