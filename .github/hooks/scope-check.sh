#!/usr/bin/env bash
# Scope enforcement hook for CitySlop agents.
# Checks that file edits stay within the agent's ALLOWED_PATHS.
#
# Input: JSON on stdin from Copilot hook system (PreToolUse event)
# Environment: ALLOWED_PATHS — comma-separated glob patterns of allowed paths
# Output: JSON with permissionDecision (allow/deny)

set -euo pipefail

INPUT=$(cat)

# Extract tool name and file path from hook input
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('toolName',''))" 2>/dev/null || echo "")
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
params = d.get('toolInput', {})
# Try common parameter names for file paths
for key in ('filePath', 'file', 'path', 'uri'):
    if key in params:
        print(params[key])
        sys.exit(0)
print('')
" 2>/dev/null || echo "")

# Only check file-editing tools
case "$TOOL_NAME" in
    replace_string_in_file|create_file|multi_replace_string_in_file|edit_notebook_file)
        ;;
    *)
        # Non-file-edit tools are always allowed
        echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
        exit 0
        ;;
esac

# If no file path detected, allow (can't enforce what we can't parse)
if [[ -z "$FILE_PATH" ]]; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
fi

# If no ALLOWED_PATHS set, allow everything
if [[ -z "${ALLOWED_PATHS:-}" ]]; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
fi

# Make path relative to workspace root
WORKSPACE_ROOT="${BUILD_WORKSPACE_DIRECTORY:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
REL_PATH="${FILE_PATH#$WORKSPACE_ROOT/}"

# Check against allowed patterns
IFS=',' read -ra PATTERNS <<< "$ALLOWED_PATHS"
for pattern in "${PATTERNS[@]}"; do
    pattern=$(echo "$pattern" | xargs)  # trim whitespace
    # Use bash extended globbing to match
    if [[ "$REL_PATH" == $pattern ]]; then
        echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
        exit 0
    fi
    # Also try with ** expansion via find-style matching
    if python3 -c "
import fnmatch, sys
if fnmatch.fnmatch('$REL_PATH', '$pattern'):
    sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
        echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
        exit 0
    fi
done

# Path not in allowed set — deny with explanation
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"File '$REL_PATH' is outside this agent's scope. Allowed paths: $ALLOWED_PATHS\"}}"
exit 0
