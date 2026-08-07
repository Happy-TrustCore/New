"use client";

import { useEffect, useMemo, useState, useTransition } from "react";
import { useTranslations } from "next-intl";
import { useRouter } from "@/i18n/navigation";
import CodeMirror from "@uiw/react-codemirror";
import { html } from "@codemirror/lang-html";
import { css } from "@codemirror/lang-css";
import { javascript } from "@codemirror/lang-javascript";
import { submitPractice } from "@/lib/actions/practice";
import type { StarterCode } from "@/lib/supabase/types";

type Lang = "html" | "css" | "js";

const LANG_LABEL: Record<Lang, string> = { html: "HTML", css: "CSS", js: "JS" };

function getExtensions(lang: Lang) {
  switch (lang) {
    case "html":
      return [html()];
    case "css":
      return [css()];
    case "js":
      return [javascript()];
  }
}

function buildPreviewDoc(code: Record<Lang, string>, enabled: Lang[]) {
  const bodyHtml = enabled.includes("html") ? code.html : "";
  const styleTag = enabled.includes("css") ? `<style>${code.css}</style>` : "";
  const scriptTag = enabled.includes("js") ? `<script>${code.js}<\/script>` : "";

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

  return `<!doctype html><html><head>${consoleShim}${styleTag}</head><body>${bodyHtml}${scriptTag}</body></html>`;
}

export function CodeWorkspace({
  lessonId,
  starterCode,
  practicePassed,
}: {
  lessonId: string;
  starterCode: StarterCode | null;
  practicePassed: boolean;
}) {
  const router = useRouter();
  const t = useTranslations("learn.editor");
  const [isPending, startTransition] = useTransition();

  const enabled = useMemo<Lang[]>(() => {
    const langs: Lang[] = [];
    if (starterCode?.html !== undefined) langs.push("html");
    if (starterCode?.css !== undefined) langs.push("css");
    if (starterCode?.js !== undefined) langs.push("js");
    return langs.length > 0 ? langs : ["html"];
  }, [starterCode]);

  const [code, setCode] = useState<Record<Lang, string>>({
    html: starterCode?.html ?? "<h1>Hello</h1>",
    css: starterCode?.css ?? "",
    js: starterCode?.js ?? "",
  });
  const [activeTab, setActiveTab] = useState<Lang>(enabled[0]);
  const [srcDoc, setSrcDoc] = useState(() => buildPreviewDoc(code, enabled));
  const [consoleLines, setConsoleLines] = useState<{ type: string; text: string }[]>([]);
  const [saveState, setSaveState] = useState<"idle" | "done" | "error">(
    practicePassed ? "done" : "idle"
  );

  useEffect(() => {
    function handleMessage(event: MessageEvent) {
      if (event.data?.source !== "codepath-preview") return;
      setConsoleLines((lines) => [...lines, { type: event.data.type, text: event.data.text }]);
    }
    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, []);

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

  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center justify-between border-b border-border px-3 py-2">
        <div className="flex gap-1">
          {enabled.map((lang) => (
            <button
              key={lang}
              onClick={() => setActiveTab(lang)}
              className={`rounded-md px-3 py-1 font-mono text-xs ${
                activeTab === lang
                  ? "bg-surface-2 text-foreground"
                  : "text-muted hover:text-foreground"
              }`}
            >
              {LANG_LABEL[lang]}
            </button>
          ))}
        </div>
        <button
          onClick={runCode}
          className="rounded-lg bg-accent px-3 py-1.5 text-xs font-semibold text-accent-foreground hover:opacity-90"
        >
          ▶ {t("run")}
        </button>
      </div>

      <div className="min-h-0 flex-[2]">
        <CodeMirror
          value={code[activeTab]}
          height="100%"
          theme="dark"
          extensions={getExtensions(activeTab)}
          onChange={(value) => setCode((c) => ({ ...c, [activeTab]: value }))}
        />
      </div>

      <div className="flex min-h-0 flex-[2] flex-col border-t border-border">
        <div className="border-b border-border bg-surface-2 px-3 py-1.5 text-xs font-mono text-muted">
          {t("preview")}
        </div>
        <iframe
          srcDoc={srcDoc}
          sandbox="allow-scripts"
          title={t("preview")}
          className="min-h-0 flex-1 bg-white"
        />
        <div className="h-24 shrink-0 overflow-y-auto border-t border-border bg-black px-3 py-2 font-mono text-xs">
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

      <div className="shrink-0 border-t border-border p-3">
        <button
          onClick={handleComplete}
          disabled={isPending || saveState === "done"}
          className="w-full rounded-lg bg-accent py-2 text-sm font-semibold text-accent-foreground transition hover:opacity-90 disabled:opacity-60"
        >
          {isPending ? t("saving") : saveState === "done" ? `✓ ${t("practiceComplete")}` : t("markPracticeComplete")}
        </button>
        {saveState === "error" && (
          <p className="mt-2 text-xs text-red-400">{t("saveError")}</p>
        )}
      </div>
    </div>
  );
}
