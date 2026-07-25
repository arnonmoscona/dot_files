#!/usr/bin/env python3
"""Condense Claude Code JSONL transcripts into a readable digest for process review.

Keeps user/assistant text in full. Strips routine Read/Glob/Grep/TodoWrite/Task*
tool calls entirely (low signal, high volume). Keeps Bash/Edit/Write/Agent/
AskUserQuestion/ExitPlanMode/SendMessage tool calls and any erroring tool call,
truncated. Drops thinking blocks (internal, not user-visible).

Usage: digest.py <output_dir> <since_iso> [<jsonl files...>]
Writes one digest_<YYYY-MM-DD>.md file per calendar day under output_dir.
"""
import json
import sys
import os
from datetime import datetime

TEXT_CAP = 4000
TOOL_INPUT_CAP = 250
TOOL_RESULT_CAP = 200
TOOL_RESULT_CAP_HIGH_SIGNAL = 600  # Bash, Edit, Write, Agent, AskUserQuestion, errors

LOW_SIGNAL_TOOLS = {"Read", "Glob", "Grep", "TodoWrite", "TaskUpdate", "TaskGet",
                     "TaskList", "TaskCreate", "BashOutput", "ListMcpResourcesTool"}
HIGH_SIGNAL_TOOLS = {"Bash", "Edit", "Write", "Agent", "AskUserQuestion",
                      "ExitPlanMode", "SendMessage"}


def truncate(s, cap):
    if s is None:
        return ""
    s = str(s)
    if len(s) <= cap:
        return s
    return s[:cap] + f"...[truncated {len(s) - cap} chars]"


def render_content_block(block, tool_names):
    """tool_names maps tool_use_id -> tool name, accumulated across the file so
    a later tool_result block can look up which tool it belongs to."""
    t = block.get("type")
    if t == "text":
        return truncate(block.get("text", ""), TEXT_CAP)
    if t == "thinking":
        return None
    if t == "tool_use":
        name = block.get("name")
        tool_id = block.get("id")
        if tool_id:
            tool_names[tool_id] = name
        if name in LOW_SIGNAL_TOOLS:
            return None
        inp = json.dumps(block.get("input", {}))
        return f"[TOOL_USE {name}] {truncate(inp, TOOL_INPUT_CAP)}"
    if t == "tool_result":
        tool_id = block.get("tool_use_id")
        name = tool_names.get(tool_id, "?")
        content = block.get("content")
        if isinstance(content, list):
            parts = [c.get("text", "") for c in content
                     if isinstance(c, dict) and c.get("type") == "text"]
            content = "\n".join(parts)
        is_error = block.get("is_error")
        if not is_error and name in LOW_SIGNAL_TOOLS:
            return None
        cap = TOOL_RESULT_CAP_HIGH_SIGNAL if (is_error or name in HIGH_SIGNAL_TOOLS) else TOOL_RESULT_CAP
        prefix = f"[TOOL_RESULT {name} ERROR]" if is_error else f"[TOOL_RESULT {name}]"
        return f"{prefix} {truncate(content, cap)}"
    return None


def process_file(path, since_dt, get_handle):
    tool_names = {}
    with open(path, "r", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except Exception:
                continue
            ts = d.get("timestamp")
            if not ts:
                continue
            try:
                dt = datetime.strptime(ts[:19], "%Y-%m-%dT%H:%M:%S")
            except Exception:
                continue
            if dt < since_dt:
                continue
            if d.get("type") not in ("user", "assistant"):
                continue
            if d.get("isMeta"):
                continue
            msg = d.get("message", {})
            role = msg.get("role", d.get("type"))
            content = msg.get("content")
            lines_out = []
            if isinstance(content, str):
                txt = truncate(content, TEXT_CAP)
                if txt.strip():
                    lines_out.append(txt)
            elif isinstance(content, list):
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    r = render_content_block(block, tool_names)
                    if r:
                        lines_out.append(r)
            if not lines_out:
                continue
            handle = get_handle(dt.strftime("%Y-%m-%d"))
            handle.write(f"\n--- [{ts}] {role.upper()} (session {d.get('sessionId', '?')[:8]}) ---\n")
            for l in lines_out:
                handle.write(l + "\n")


def main():
    out_dir = sys.argv[1]
    since_iso = sys.argv[2]
    files = sys.argv[3:]
    since_dt = datetime.strptime(since_iso, "%Y-%m-%d")
    os.makedirs(out_dir, exist_ok=True)

    handles = {}

    def get_handle(day):
        if day not in handles:
            handles[day] = open(os.path.join(out_dir, f"digest_{day}.md"), "a")
        return handles[day]

    for f in files:
        process_file(f, since_dt, get_handle)

    for h in handles.values():
        h.close()

    for day in sorted(handles.keys()):
        p = os.path.join(out_dir, f"digest_{day}.md")
        print(f"{p}: {os.path.getsize(p) / 1e6:.2f}MB")


if __name__ == "__main__":
    main()
