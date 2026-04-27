/* global React */
const { useState, useEffect, useRef, useMemo, useCallback } = React;

/* ───── Tiny inline icon set ───── */
function Icon({ name, size = 14, stroke = 1.6, ...rest }) {
  const c = "currentColor";
  const common = {
    width: size,
    height: size,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: c,
    strokeWidth: stroke,
    strokeLinecap: "round",
    strokeLinejoin: "round",
    ...rest,
  };
  switch (name) {
    case "search":
      return (
        <svg {...common}>
          <circle cx="11" cy="11" r="7" />
          <path d="m20 20-3.5-3.5" />
        </svg>
      );
    case "settings":
      return (
        <svg {...common}>
          <circle cx="12" cy="12" r="3" />
          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
        </svg>
      );
    case "pin":
      return (
        <svg {...common}>
          <line x1="12" y1="17" x2="12" y2="22" />
          <path d="M5 17h14v-1.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V6h1V4H8v2h1v4.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24Z" />
        </svg>
      );
    case "trash":
      return (
        <svg {...common}>
          <path d="M3 6h18" />
          <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6" />
          <path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
        </svg>
      );
    case "copy":
      return (
        <svg {...common}>
          <rect x="9" y="9" width="13" height="13" rx="2" />
          <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
        </svg>
      );
    case "share":
      return (
        <svg {...common}>
          <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" />
          <polyline points="16 6 12 2 8 6" />
          <line x1="12" y1="2" x2="12" y2="15" />
        </svg>
      );
    case "edit":
      return (
        <svg {...common}>
          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
          <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5Z" />
        </svg>
      );
    case "code":
      return (
        <svg {...common}>
          <polyline points="16 18 22 12 16 6" />
          <polyline points="8 6 2 12 8 18" />
        </svg>
      );
    case "palette":
      return (
        <svg {...common}>
          <circle cx="13.5" cy="6.5" r="1.5" />
          <circle cx="17.5" cy="10.5" r="1.5" />
          <circle cx="8.5" cy="7.5" r="1.5" />
          <circle cx="6.5" cy="12.5" r="1.5" />
          <path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.93 0 1.5-.7 1.5-1.5 0-.4-.18-.8-.5-1.07-.31-.27-.5-.66-.5-1.06 0-.83.67-1.5 1.5-1.5H16a6 6 0 0 0 6-6c0-5.5-4.5-9.86-10-9.86Z" />
        </svg>
      );
    case "heart":
      return (
        <svg {...common}>
          <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
        </svg>
      );
    case "all":
      return (
        <svg {...common}>
          <path d="M3 3h7v7H3zM14 3h7v7h-7zM14 14h7v7h-7zM3 14h7v7H3z" />
        </svg>
      );
    case "plus":
      return (
        <svg {...common}>
          <line x1="12" y1="5" x2="12" y2="19" />
          <line x1="5" y1="12" x2="19" y2="12" />
        </svg>
      );
    case "check":
      return (
        <svg {...common}>
          <polyline points="20 6 9 17 4 12" />
        </svg>
      );
    case "cloud":
      return (
        <svg {...common}>
          <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" />
        </svg>
      );
    case "kbd":
      return (
        <svg {...common}>
          <rect x="2" y="4" width="20" height="16" rx="2" />
          <path d="M6 8h.01M10 8h.01M14 8h.01M18 8h.01M8 12h.01M12 12h.01M16 12h.01M7 16h10" />
        </svg>
      );
    case "x":
      return (
        <svg {...common}>
          <line x1="18" y1="6" x2="6" y2="18" />
          <line x1="6" y1="6" x2="18" y2="18" />
        </svg>
      );
    case "macbook":
      return (
        <svg {...common}>
          <rect x="3" y="4" width="18" height="12" rx="2" />
          <path d="M2 20h20" />
        </svg>
      );
    case "iphone":
      return (
        <svg {...common}>
          <rect x="7" y="2" width="10" height="20" rx="2" />
          <line x1="11" y1="18" x2="13" y2="18" />
        </svg>
      );
    case "ipad":
      return (
        <svg {...common}>
          <rect x="4" y="2" width="16" height="20" rx="2" />
          <line x1="11" y1="19" x2="13" y2="19" />
        </svg>
      );
    case "list":
      return (
        <svg {...common}>
          <line x1="8" y1="6" x2="21" y2="6" />
          <line x1="8" y1="12" x2="21" y2="12" />
          <line x1="8" y1="18" x2="21" y2="18" />
          <circle cx="4" cy="6" r="0.8" />
          <circle cx="4" cy="12" r="0.8" />
          <circle cx="4" cy="18" r="0.8" />
        </svg>
      );
    default:
      return null;
  }
}

/* ───── helpers ───── */
function highlight(text, query) {
  if (!query) return text;
  const re = new RegExp(`(${query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")})`, "gi");
  const parts = text.split(re);
  return parts.map((p, i) =>
    re.test(p) ? <mark className="hl" key={i}>{p}</mark> : <span key={i}>{p}</span>
  );
}

function tokenizeJS(line) {
  const out = [];
  const keys = ["export","function","const","let","return","if","else","useState","useEffect","setTimeout","clearTimeout"];
  const types = ["T","string","number","boolean"];
  const re = /(\/\/.*$|"[^"]*"|'[^']*'|\b\d+\b|\b\w+\b|[<>(){}[\];=,.+\-*/:?])/g;
  let m, last = 0;
  while ((m = re.exec(line)) !== null) {
    if (m.index > last) out.push({ t: "p", v: line.slice(last, m.index) });
    const tok = m[0];
    if (tok.startsWith("//")) out.push({ t: "cmt", v: tok });
    else if (tok.startsWith('"') || tok.startsWith("'")) out.push({ t: "str", v: tok });
    else if (/^\d+$/.test(tok)) out.push({ t: "num", v: tok });
    else if (keys.includes(tok)) out.push({ t: "key", v: tok });
    else if (types.includes(tok)) out.push({ t: "type", v: tok });
    else out.push({ t: "p", v: tok });
    last = re.lastIndex;
  }
  if (last < line.length) out.push({ t: "p", v: line.slice(last) });
  return out;
}
function tokenizeSQL(line) {
  const out = [];
  const keys = ["SELECT","FROM","WHERE","AND","OR","GROUP","BY","ORDER","LIMIT","COUNT","DESC","ASC","interval","now"];
  const re = /(--.*$|'[^']*'|\b\d+\b|\b\w+\b|[*=<>(),.;])/g;
  let m, last = 0;
  while ((m = re.exec(line)) !== null) {
    if (m.index > last) out.push({ t: "p", v: line.slice(last, m.index) });
    const tok = m[0];
    if (tok.startsWith("--")) out.push({ t: "cmt", v: tok });
    else if (tok.startsWith("'")) out.push({ t: "str", v: tok });
    else if (/^\d+$/.test(tok)) out.push({ t: "num", v: tok });
    else if (keys.includes(tok.toUpperCase()) && /^[a-z]/i.test(tok)) out.push({ t: "key", v: tok });
    else out.push({ t: "p", v: tok });
    last = re.lastIndex;
  }
  if (last < line.length) out.push({ t: "p", v: line.slice(last) });
  return out;
}
function tokenizeShell(line) {
  const out = [];
  const re = /(#.*$|"[^"]*"|'[^']*'|\$?\b[A-Z_][A-Z0-9_]+\b|\b\w+\b|[\\&|=])/g;
  let m, last = 0;
  while ((m = re.exec(line)) !== null) {
    if (m.index > last) out.push({ t: "p", v: line.slice(last, m.index) });
    const tok = m[0];
    if (tok.startsWith("#")) out.push({ t: "cmt", v: tok });
    else if (tok.startsWith('"') || tok.startsWith("'")) out.push({ t: "str", v: tok });
    else if (/^[A-Z_]+$/.test(tok)) out.push({ t: "type", v: tok });
    else if (["pnpm","npm","node","aws","cd","ls","echo"].includes(tok)) out.push({ t: "key", v: tok });
    else out.push({ t: "p", v: tok });
    last = re.lastIndex;
  }
  if (last < line.length) out.push({ t: "p", v: line.slice(last) });
  return out;
}

function CodeBlock({ content, language }) {
  const lines = content.split("\n");
  const tokenize =
    language === "SQL" ? tokenizeSQL :
    language === "Shell" ? tokenizeShell :
    tokenizeJS;
  return (
    <pre>{lines.map((line, i) => (
      <div key={i}>{tokenize(line).map((t, j) =>
        t.t === "p"
          ? <span key={j}>{t.v}</span>
          : <span key={j} className={`tk-${t.t}`}>{t.v}</span>
      )}</div>
    ))}</pre>
  );
}

function getDomain(url) {
  try { return new URL(url).hostname.replace(/^www\./, ""); }
  catch { return url; }
}

function hexToRgb(hex) {
  const h = hex.replace("#", "");
  const num = parseInt(h, 16);
  return [num >> 16 & 255, num >> 8 & 255, num & 255];
}
function rgbToHsl(r, g, b) {
  r/=255; g/=255; b/=255;
  const max = Math.max(r,g,b), min = Math.min(r,g,b);
  let h, s, l = (max + min) / 2;
  if (max === min) { h = s = 0; }
  else {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = (g - b) / d + (g < b ? 6 : 0); break;
      case g: h = (b - r) / d + 2; break;
      case b: h = (r - g) / d + 4; break;
    }
    h /= 6;
  }
  return [Math.round(h*360), Math.round(s*100), Math.round(l*100)];
}

Object.assign(window, { Icon, highlight, CodeBlock, getDomain, hexToRgb, rgbToHsl });
