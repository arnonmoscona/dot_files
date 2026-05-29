#!/bin/bash
#
# Open an Obsidian note by its title property.
# Uses Advanced URI plugin's eval feature to search and open.
#
# Usage:
#   open_note_by_title.sh "My Note Title"
#   open_note_by_title.sh "FLO-113 Pre-Tool-Use Hook Permission System"
#
# Requirements:
#   - Obsidian Advanced URI plugin with "Evaluate" enabled
#

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 \"Note Title\"" >&2
    echo "Example: $0 \"FLO-113 Pre-Tool-Use Hook Permission System\"" >&2
    exit 1
fi

TITLE="$1"
VAULT="Obsidian%20Vault"

# URL-encode the title
# This handles spaces, quotes, and special characters
url_encode() {
    local string="$1"
    local encoded=""
    local i char

    for (( i=0; i<${#string}; i++ )); do
        char="${string:i:1}"
        case "$char" in
            [a-zA-Z0-9.~_-])
                encoded+="$char"
                ;;
            ' ')
                encoded+="%20"
                ;;
            *)
                # Convert to hex
                encoded+=$(printf '%%%02X' "'$char")
                ;;
        esac
    done
    echo "$encoded"
}

ENCODED_TITLE=$(url_encode "$TITLE")

# Build the JavaScript code
# const files=app.vault.getMarkdownFiles();const target="TITLE";for(const f of files){const c=app.metadataCache.getFileCache(f);if(c?.frontmatter?.title===target){app.workspace.openLinkText(f.path,"",true);break}}
JS_CODE="const files=app.vault.getMarkdownFiles();const target=\"${TITLE}\";for(const f of files){const c=app.metadataCache.getFileCache(f);if(c?.frontmatter?.title===target){app.workspace.openLinkText(f.path,\"\",true);break}}"

# URL-encode the JavaScript
ENCODED_JS=$(url_encode "$JS_CODE")

# Build and execute the URI
URI="obsidian://advanced-uri?vault=${VAULT}&eval=${ENCODED_JS}"

open "$URI"
