# Claude Code Conversation Logging

This directory contains hooks that automatically archive Claude Code conversation transcripts.

## Setup

The conversation logger is already configured and will run automatically at the end of each Claude Code session.

### What Gets Logged

When a Claude Code session ends, the full conversation transcript is saved to:
- **Location**: `~/.claude/conversation-logs/`
- **Format**: Both JSON (full transcript) and TXT (summary)
- **Filename**: `YYYY-MM-DD_HH-MM-SS_<session-id>.json` and `.txt`

### Log Contents

Each conversation generates two files:

1. **JSON file** (`*_<session-id>.json`): Complete conversation transcript including:
   - All user messages
   - All assistant responses
   - Tool calls and results
   - Full conversation context

2. **TXT file** (`*_<session-id>.txt`): Human-readable summary including:
   - Session ID
   - Timestamp
   - End reason
   - First message (as a title)
   - Path to full JSON transcript

### Viewing Logs

```bash
# List all logged conversations
ls -lh ~/.claude/conversation-logs/

# View a summary
cat ~/.claude/conversation-logs/2025-10-22_16-30-00_<session-id>.txt

# View full transcript (formatted)
jq '.' ~/.claude/conversation-logs/2025-10-22_16-30-00_<session-id>.json

# Search conversations by content
grep -r "search term" ~/.claude/conversation-logs/*.txt
```

### Configuration

The hook is configured in `.claude/settings.local.json`:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/log-conversation.sh"
          }
        ]
      }
    ]
  }
}
```

### Cleanup

Conversation logs are stored indefinitely. To manage disk space:

```bash
# Remove logs older than 30 days
find ~/.claude/conversation-logs/ -type f -mtime +30 -delete

# Remove all logs
rm -rf ~/.claude/conversation-logs/
```

### Disabling Logging

To disable automatic logging, remove the `hooks` section from `.claude/settings.local.json`.

## Implementation Details

The `log-conversation.sh` script:
1. Receives session end event via stdin (JSON format)
2. Extracts `transcript_path` from the event data
3. Copies the transcript to the archive directory
4. Creates a human-readable summary
5. Uses timestamps for unique, sortable filenames

The hook runs automatically and silently - no user interaction required.
