#!/usr/bin/env python3
"""Snapshot the JetBrains IDE MCP server's capabilities and report drift.

The IDE's MCP surface changes with IDE and plugin updates, and its published docs run
ahead of what a given build actually ships (verified: docs describe `analyze_calls`;
build 2026.1.3 does not expose it). Guidance written against the docs therefore rots
silently, and the failure mode is a wasted turn on an uncallable tool.

This queries the live server for the authoritative tool list, stores a snapshot, and
diffs against the previous one. It is silent when nothing changed, so it can run from a
SessionStart hook at no token cost.

Usage:
    ide_mcp_capabilities.py            # check for drift; silent if none
    ide_mcp_capabilities.py --verbose  # always print a summary
    ide_mcp_capabilities.py --list     # print the current tool names and exit
    ide_mcp_capabilities.py --show TOOL  # print one tool's full schema
    ide_mcp_capabilities.py --json     # machine-readable drift report

Exit codes: 0 = no drift (or drift recorded successfully), 2 = server unreachable.
Standard library only; no threads.
"""

import argparse
import datetime
import difflib
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

DEFAULT_BASE = "http://127.0.0.1:64342"
STORE = Path.home() / ".claude" / "ide-mcp"
PROTOCOL = "2024-11-05"


class Unreachable(Exception):
    """The IDE MCP server could not be contacted."""


def _read_event(stream):
    """Read a single SSE event from an open stream, returning (event, data)."""
    event, data = None, []
    for raw in stream:
        line = raw.decode("utf-8", "replace").rstrip("\r\n")
        if line == "":
            if event or data:
                return event, "\n".join(data)
            continue
        if line.startswith(":"):
            continue
        field, _, value = line.partition(":")
        if field == "event":
            event = value.lstrip(" ")
        elif field == "data":
            data.append(value.lstrip(" "))
    return None, None


def fetch_capabilities(base=DEFAULT_BASE, timeout=20):
    """Query the live MCP server. Returns {serverInfo, protocolVersion, tools}."""
    try:
        req = urllib.request.Request(f"{base}/sse", method="GET")
        req.add_header("Accept", "text/event-stream")
        stream = urllib.request.urlopen(req, timeout=timeout)
    except Exception as exc:  # noqa: BLE001 - any transport failure means "not running"
        raise Unreachable(f"{type(exc).__name__}: {exc}") from exc

    try:
        event, endpoint = _read_event(stream)
        if event != "endpoint" or not endpoint:
            raise Unreachable(f"unexpected handshake event {event!r}")

        def call(payload, expect_reply=True):
            url = urllib.parse.urljoin(base, endpoint)
            post = urllib.request.Request(
                url, data=json.dumps(payload).encode(), method="POST"
            )
            post.add_header("Content-Type", "application/json")
            with urllib.request.urlopen(post, timeout=timeout):
                pass
            if not expect_reply:
                return None
            _, data = _read_event(stream)
            return json.loads(data) if data else None

        init = call({
            "jsonrpc": "2.0", "id": 1, "method": "initialize",
            "params": {
                "protocolVersion": PROTOCOL, "capabilities": {},
                "clientInfo": {"name": "ide-mcp-capability-snapshot", "version": "1"},
            },
        })
        call({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}},
             expect_reply=False)
        listed = call({"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}})
    finally:
        stream.close()

    result = (init or {}).get("result", {})
    tools = ((listed or {}).get("result") or {}).get("tools") or []
    return {
        "capturedAt": datetime.datetime.now().isoformat(timespec="seconds"),
        "serverInfo": result.get("serverInfo", {}),
        "protocolVersion": result.get("protocolVersion"),
        "tools": {
            t["name"]: {
                "description": (t.get("description") or "").strip(),
                "inputSchema": t.get("inputSchema") or {},
            }
            for t in tools
        },
    }


def _params(tool):
    schema = tool.get("inputSchema") or {}
    props = set((schema.get("properties") or {}).keys())
    required = set(schema.get("required") or [])
    return props, required


def diff(old, new):
    """Compare two snapshots. Returns a dict describing every material change."""
    if not old:
        return {"first_run": True, "tool_count": len(new["tools"])}

    old_tools, new_tools = old.get("tools", {}), new["tools"]
    report = {
        "first_run": False,
        "version_changed": old.get("serverInfo", {}).get("version")
        != new.get("serverInfo", {}).get("version"),
        "old_version": old.get("serverInfo", {}).get("version"),
        "new_version": new.get("serverInfo", {}).get("version"),
        "added": sorted(set(new_tools) - set(old_tools)),
        "removed": sorted(set(old_tools) - set(new_tools)),
        "changed": {},
    }
    for name in sorted(set(old_tools) & set(new_tools)):
        before, after = old_tools[name], new_tools[name]
        entry = {}
        old_props, old_req = _params(before)
        new_props, new_req = _params(after)
        if new_props - old_props:
            entry["params_added"] = sorted(new_props - old_props)
        if old_props - new_props:
            entry["params_removed"] = sorted(old_props - new_props)
        if new_req != old_req:
            entry["required_changed"] = {
                "added": sorted(new_req - old_req),
                "removed": sorted(old_req - new_req),
            }
        if before.get("description") != after.get("description"):
            entry["description_changed"] = True
        if entry:
            report["changed"][name] = entry
    report["has_drift"] = bool(
        report["added"] or report["removed"] or report["changed"]
        or report["version_changed"]
    )
    return report


def render(report, new):
    """Render a drift report as short, actionable prose."""
    if report.get("first_run"):
        return (
            f"IDE MCP capability baseline recorded: "
            f"{new['serverInfo'].get('name', 'server')} "
            f"{new['serverInfo'].get('version', '?')}, "
            f"{report['tool_count']} tools. Drift will be reported from now on."
        )
    if not report["has_drift"]:
        return ""

    lines = ["IDE MCP CAPABILITY DRIFT DETECTED"]
    if report["version_changed"]:
        lines.append(
            f"  server version: {report['old_version']} -> {report['new_version']}"
        )
    if report["added"]:
        lines.append(f"  NEW tools ({len(report['added'])}): "
                     + ", ".join(report["added"]))
    if report["removed"]:
        lines.append(f"  REMOVED tools ({len(report['removed'])}): "
                     + ", ".join(report["removed"]))
    for name, entry in report["changed"].items():
        bits = []
        for key in ("params_added", "params_removed"):
            if key in entry:
                bits.append(f"{key.replace('_', ' ')}: {', '.join(entry[key])}")
        if "required_changed" in entry:
            rc = entry["required_changed"]
            if rc["added"]:
                bits.append(f"now required: {', '.join(rc['added'])}")
            if rc["removed"]:
                bits.append(f"no longer required: {', '.join(rc['removed'])}")
        if entry.get("description_changed"):
            bits.append("description changed")
        lines.append(f"  CHANGED {name}: " + "; ".join(bits))
    lines.append(
        "  -> Re-read ~/.claude/reference/ide-mcp.md and re-verify any recipe that "
        "touches a changed tool; append what you find to ide-mcp-evidence.md."
    )
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--base", default=DEFAULT_BASE, help="MCP server base URL")
    ap.add_argument("--verbose", action="store_true",
                    help="print a summary even when nothing changed")
    ap.add_argument("--list", action="store_true", help="print tool names and exit")
    ap.add_argument("--show", metavar="TOOL", help="print one tool's full schema")
    ap.add_argument("--json", action="store_true", help="emit the drift report as JSON")
    ap.add_argument("--no-save", action="store_true",
                    help="do not update the stored snapshot")
    args = ap.parse_args()

    try:
        new = fetch_capabilities(args.base)
    except Unreachable as exc:
        # An IDE that isn't running is the normal case, not an error worth shouting about.
        if args.verbose or args.list or args.show:
            print(f"IDE MCP server unreachable at {args.base} ({exc})", file=sys.stderr)
        return 2

    if args.list:
        for name in sorted(new["tools"]):
            print(name)
        return 0

    if args.show:
        tool = new["tools"].get(args.show)
        if not tool:
            print(f"no such tool: {args.show}", file=sys.stderr)
            close = difflib.get_close_matches(args.show, new["tools"], n=5)
            if close:
                print("did you mean: " + ", ".join(close), file=sys.stderr)
            return 1
        print(json.dumps({args.show: tool}, indent=2))
        return 0

    STORE.mkdir(parents=True, exist_ok=True)
    latest = STORE / "latest.json"
    old = json.loads(latest.read_text()) if latest.exists() else None
    report = diff(old, new)

    if not args.no_save and (report.get("first_run") or report.get("has_drift")):
        version = (new["serverInfo"].get("version") or "unknown").replace("/", "_")
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        history = STORE / "history"
        history.mkdir(exist_ok=True)
        (history / f"{stamp}-{version}.json").write_text(json.dumps(new, indent=2))
        latest.write_text(json.dumps(new, indent=2))

    if args.json:
        print(json.dumps(report, indent=2))
        return 0

    text = render(report, new)
    if text:
        print(text)
    elif args.verbose:
        print(
            f"IDE MCP unchanged: {new['serverInfo'].get('name')} "
            f"{new['serverInfo'].get('version')}, {len(new['tools'])} tools."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
