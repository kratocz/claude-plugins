#!/usr/bin/env bash
# Shared helpers for session-log plugin.

# Encode a filesystem path the same way Claude Code does for ~/.claude/projects/.
# Both "/" and "." become "-", so:
#   /home/user/code/app        -> -home-user-code-app
#   /home/user/.claude/plugins -> -home-user--claude-plugins
# This matches the encoded dir names CC uses to store session JSONL transcripts,
# which means our logs/<encoded-cwd>/ directly mirrors ~/.claude/projects/<same>/.
encode_cwd() {
  printf '%s' "$1" | tr './' '--'
}

# Extract first "real" user message from a JSONL transcript.
# Skips meta messages and wrappers like <command-name>, <local-command-stdout>,
# <local-command-caveat>, <system-reminder> that aren't actual user prompts.
# Truncates to 300 chars.
extract_goal() {
  local transcript="$1"
  # jq -c emits each match as a one-line JSON-encoded string. That keeps
  # multi-line user messages on a single line so head -1 picks the entire
  # first message. The second jq call decodes it back to plain text.
  jq -c '
    select(.type == "user" and (.isMeta // false) == false) |
    (.message.content |
      if type == "string" then .
      else (map(select(.type == "text")) | .[0].text // "")
      end
    ) |
    select(. != null and . != "") |
    select(startswith("<") | not)
  ' "$transcript" 2>/dev/null | head -1 | jq -r '.' 2>/dev/null | cut -c1-300
}

# Convert an ISO 8601 timestamp to Unix epoch — portable across Linux and macOS.
# Handles milliseconds (.NNN) and Z/+HH:MM timezone suffixes.
_to_epoch() {
  local ts="${1%%.*}"    # strip milliseconds: "...T06:27:12.158Z" → "...T06:27:12Z"
  ts="${ts%Z}"           # strip trailing Z: "...T06:27:12Z" → "...T06:27:12"
  ts="${ts%%+*}"         # strip +HH:MM offset if present
  if command -v gdate &>/dev/null; then          # GNU coreutils (brew install coreutils)
    gdate -d "$ts" +%s 2>/dev/null
  elif [[ "${OSTYPE:-}" == "darwin"* ]]; then    # stock macOS BSD date
    date -j -u -f "%Y-%m-%dT%H:%M:%S" "$ts" +%s 2>/dev/null
  else                                            # GNU date on Linux
    date -d "$ts" +%s 2>/dev/null
  fi
}

# Human-readable duration between two ISO timestamps.
# Returns "1h23m" / "42m" / "15s" form.
format_duration() {
  local start_ts="$1"
  local end_ts="$2"
  local start_epoch end_epoch secs h m s
  start_epoch=$(_to_epoch "$start_ts") || return
  end_epoch=$(_to_epoch "$end_ts") || return
  secs=$((end_epoch - start_epoch))
  [ "$secs" -lt 0 ] && secs=0
  h=$((secs / 3600))
  m=$(( (secs % 3600) / 60 ))
  s=$((secs % 60))
  if [ "$h" -gt 0 ]; then
    printf '%dh%dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then
    printf '%dm' "$m"
  else
    printf '%ds' "$s"
  fi
}

# Count assistant messages (= turns).
count_turns() {
  local transcript="$1"
  jq -c 'select(.type == "assistant")' "$transcript" 2>/dev/null | wc -l | tr -d ' '
}

# Unique file paths from Edit/Write/NotebookEdit tool calls.
# Each line: "<action>\t<path>" — action ∈ {edit, write, notebook-edit}.
extract_files_touched() {
  local transcript="$1"
  jq -r '
    select(.type == "assistant" and (.message.content | type == "array")) |
    .message.content[] |
    select(.type == "tool_use") |
    select(.name == "Edit" or .name == "Write" or .name == "NotebookEdit") |
    (
      if .name == "Edit" then "edit"
      elif .name == "Write" then "write"
      else "notebook-edit" end
    ) + "\t" + (.input.file_path // .input.notebook_path // "")
  ' "$transcript" 2>/dev/null | awk -F'\t' 'NF == 2 && $2 != "" && !seen[$2]++'
}

# Git commit messages (first line only) extracted from Bash tool calls.
extract_git_commits() {
  local transcript="$1"
  jq -r '
    select(.type == "assistant" and (.message.content | type == "array")) |
    .message.content[] |
    select(.type == "tool_use" and .name == "Bash") |
    .input.command // empty |
    select(test("git +commit"))
  ' "$transcript" 2>/dev/null | \
    sed -nE "s/.*-m ['\"]([^'\"]+).*/\1/p" | \
    awk 'NF' | head -20
}

# Tool usage stats: one line per tool, formatted as "  - Name: N".
extract_tool_stats() {
  local transcript="$1"
  jq -r '
    select(.type == "assistant" and (.message.content | type == "array")) |
    .message.content[] |
    select(.type == "tool_use") |
    .name
  ' "$transcript" 2>/dev/null | sort | uniq -c | sort -rn | \
    awk '{ name=$2; count=$1; printf("- %s: %d\n", name, count) }'
}

# YAML-safe single-line string (escape quotes, collapse newlines).
yaml_escape() {
  local s="$1"
  # Collapse newlines to spaces, escape double quotes
  s="${s//$'\n'/ }"
  s="${s//$'\r'/ }"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}
