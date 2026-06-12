#!/bin/bash
#
# Claude Code SessionEnd Hook - Conversation Logger
#
# This hook automatically saves full conversation transcripts when a session ends.
# The transcript JSON file is copied to a permanent location for archival.

# Read the hook input JSON from stdin
input=$(cat)

# Extract relevant fields
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
hook_event=$(echo "$input" | jq -r '.hook_event_name // empty')
reason=$(echo "$input" | jq -r '.reason // empty')

# Define the archive directory
ARCHIVE_DIR="$HOME/.claude/conversation-logs"
mkdir -p "$ARCHIVE_DIR"

# Only log if we have a transcript path
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Generate timestamp for the filename
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

    # Copy the transcript to the archive with a descriptive name
    archive_file="$ARCHIVE_DIR/${timestamp}_${session_id}.json"
    cp "$transcript_path" "$archive_file"

    # Also create a human-readable summary
    summary_file="$ARCHIVE_DIR/${timestamp}_${session_id}.txt"

    # Extract first user message as conversation title
    first_message=$(jq -r '.messages[] | select(.role=="user") | .content[0].text // .content | select(. != null)' "$transcript_path" | head -1 | cut -c1-100)

    echo "Conversation Log" > "$summary_file"
    echo "================" >> "$summary_file"
    echo "Session ID: $session_id" >> "$summary_file"
    echo "Timestamp: $timestamp" >> "$summary_file"
    echo "End Reason: $reason" >> "$summary_file"
    echo "First Message: $first_message" >> "$summary_file"
    echo "" >> "$summary_file"
    echo "Full transcript saved to: $archive_file" >> "$summary_file"

    # Log success (optional, for debugging)
    # echo "Conversation logged: $archive_file" >&2
fi

exit 0
