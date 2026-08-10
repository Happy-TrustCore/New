import { EditorView } from "@codemirror/view";
import { HighlightStyle, syntaxHighlighting } from "@codemirror/language";
import { tags as t } from "@lezer/highlight";

// A small, curated palette reusing this app's own accent colors (the same
// four used everywhere else on the site), instead of the default VS Code
// theme's much larger rainbow (10+ distinct hues for keywords, tags,
// attributes, classes, regex, etc). Fewer colors, each one already
// meaningful elsewhere in the product, reads as intentional rather than
// "generic code editor."
const ACCENT = "#34d399";
const ACCENT_2 = "#38bdf8";
const ACCENT_3 = "#a78bfa";
const ACCENT_WARM = "#fb923c";
const MUTED = "#6b7280";
const PUNCTUATION = "#8b8b9a";
const FOREGROUND = "#d4d4d8";

const highlightStyle = HighlightStyle.define([
  {
    tag: [t.keyword, t.controlKeyword, t.operatorKeyword, t.definitionKeyword, t.moduleKeyword],
    color: ACCENT_3,
  },
  { tag: [t.string, t.special(t.string)], color: ACCENT_WARM },
  { tag: [t.number, t.bool, t.atom, t.self], color: ACCENT },
  { tag: [t.function(t.variableName), t.function(t.propertyName)], color: ACCENT_2 },
  { tag: [t.tagName], color: ACCENT_3 },
  { tag: [t.attributeName], color: ACCENT_2 },
  { tag: [t.className, t.typeName], color: ACCENT_2 },
  { tag: [t.comment, t.lineComment, t.blockComment], color: MUTED, fontStyle: "italic" },
  { tag: [t.propertyName, t.variableName, t.definition(t.variableName)], color: FOREGROUND },
  { tag: [t.punctuation, t.bracket, t.angleBracket, t.operator], color: PUNCTUATION },
  { tag: t.invalid, color: "#f87171" },
]);

export const codePathEditorTheme = EditorView.theme(
  {
    "&": { backgroundColor: "#1e1e1e", color: FOREGROUND },
    ".cm-content": { caretColor: ACCENT },
    ".cm-cursor, .cm-dropCursor": { borderLeftColor: ACCENT },
    "&.cm-focused .cm-selectionBackground, .cm-selectionBackground, .cm-content ::selection": {
      backgroundColor: "rgba(52, 211, 153, 0.18)",
    },
    ".cm-activeLine": { backgroundColor: "rgba(255,255,255,0.03)" },
    ".cm-gutters": { backgroundColor: "#1e1e1e", color: "#5a5a68", border: "none" },
    ".cm-activeLineGutter": { backgroundColor: "rgba(255,255,255,0.03)" },
  },
  { dark: true }
);

export const codePathSyntaxHighlighting = syntaxHighlighting(highlightStyle);
