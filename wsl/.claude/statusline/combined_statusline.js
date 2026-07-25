#!/usr/bin/env node
"use strict";

const fs = require("fs");
const { execSync } = require("child_process");

// --- input ---
const input = readJSON(0); // stdin
const sessionId = `\x1b[90m${String(input.session_id ?? "")}\x1b[0m`;
const transcript = input.transcript_path;
const model = input.model || {};
const name = `\x1b[95m${String(model.display_name ?? "")}\x1b[0m`.trim();
const rateLimits = input.rate_limits || {};
const CONTEXT_WINDOW = 200_000;

// --- helpers ---
function readJSON(fd) {
  try {
    return JSON.parse(fs.readFileSync(fd, "utf8"));
  } catch {
    return {};
  }
}
function color(p) {
  if (p >= 90) return "\x1b[31m"; // red
  if (p >= 70) return "\x1b[33m"; // yellow
  return "\x1b[32m"; // green
}
const comma = (n) =>
  new Intl.NumberFormat("en-US").format(
    Math.max(0, Math.floor(Number(n) || 0))
  );

function usedTotal(u) {
  return (
    (u?.input_tokens ?? 0) +
    (u?.output_tokens ?? 0) +
    (u?.cache_read_input_tokens ?? 0) +
    (u?.cache_creation_input_tokens ?? 0)
  );
}

function syntheticModel(j) {
  const m = String(j?.message?.model ?? "").toLowerCase();
  return m === "<synthetic>" || m.includes("synthetic");
}

function assistantMessage(j) {
  return j?.message?.role === "assistant";
}

function subContext(j) {
  return j?.isSidechain === true;
}

function contentNoResponse(j) {
  const c = j?.message?.content;
  return (
    Array.isArray(c) &&
    c.some(
      (x) =>
        x &&
        x.type === "text" &&
        /no\s+response\s+requested/i.test(String(x.text))
    )
  );
}

function parseTs(j) {
  const t = j?.timestamp;
  const n = Date.parse(t);
  return Number.isFinite(n) ? n : -Infinity;
}

// Find the newest main-context entry by timestamp (not file order)
function newestMainUsageByTimestamp() {
  if (!transcript) return null;
  let latestTs = -Infinity;
  let latestUsage = null;

  let lines;
  try {
    lines = fs.readFileSync(transcript, "utf8").split(/\r?\n/);
  } catch {
    return null;
  }

  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i].trim();
    if (!line) continue;

    let j;
    try {
      j = JSON.parse(line);
    } catch {
      continue;
    }
    const u = j.message?.usage;
    if (
      subContext(j) ||
      syntheticModel(j) ||
      j.isApiErrorMessage === true ||
      usedTotal(u) === 0 ||
      contentNoResponse(j) ||
      !assistantMessage(j)
    )
      continue;

    const ts = parseTs(j);
    if (ts > latestTs) {
      latestTs = ts;
      latestUsage = u;
    }
    else if (ts == latestTs && usedTotal(u) > usedTotal(latestUsage)) {
      latestUsage = u;
    }
  }
  return latestUsage;
}

// Get git branch info
function getGitInfo() {
  try {
    const branch = execSync("git branch --no-color 2>/dev/null | grep '^\\*' | sed -e 's/^\\* //'", {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "ignore"]
    }).trim();
    return branch ? `\x1b[32m(${branch})\x1b[0m` : "";
  } catch {
    return "";
  }
}

// Get current working directory
function getCwd() {
  return `\x1b[33m${process.cwd()}\x1b[0m`;
}

// Get session usage % from rate_limits (5-hour window)
function getSessionUsagePart() {
  const pct = rateLimits.five_hour?.used_percentage;
  if (pct == null) return null;
  const p = Number(pct);
  let out = `${color(p)}sess ${p.toFixed(1)}%\x1b[0m`;
  if (p >= 80) {
    const resetsAt = rateLimits.five_hour?.resets_at;
    if (resetsAt != null) {
      const t = new Date(Number(resetsAt) * 1000);
      const hhmm = t.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
      out += ` \x1b[90m(resets ${hhmm})\x1b[0m`;
    }
  }
  return out;
}

// --- compute/print ---
const usage = newestMainUsageByTimestamp();
const leftPart = `${getCwd()} ${getGitInfo()}`;

const sessionUsagePart = getSessionUsagePart();

if (!usage) {
  const parts = [`${leftPart}`, `\x1b[36mcontext starts after first question\x1b[0m`];
  if (sessionUsagePart) parts.push(sessionUsagePart);
  parts.push(name);
  console.log(`${parts.join(" | ")}\nsession: ${sessionId}`);
  process.exit(0);
}

const used = usedTotal(usage);
const pct = CONTEXT_WINDOW > 0 ? Math.round((used * 1000) / CONTEXT_WINDOW) / 10 : 0;

const ctxPart = `${color(pct)}ctx ${pct.toFixed(1)}%\x1b[0m \x1b[33m(${comma(used)}/${comma(CONTEXT_WINDOW)})\x1b[0m`;

const parts = [leftPart, ctxPart];
if (sessionUsagePart) parts.push(sessionUsagePart);
parts.push(name);

console.log(`${parts.join(" | ")}\nsession: ${sessionId}`);

