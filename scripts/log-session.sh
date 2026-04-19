#!/usr/bin/env bash
# SessionEnd hook: save a structured summary of the Claude Code session.
# Never fails loudly — always exit 0 (hook is async, errors to STDERR only).
set -u

# shellcheck source=helpers.sh
source "$(dirname "$0")/helpers.sh"

warn() { >&2 echo "session-log: $*"; }

# Read payload from stdin (SessionEnd hook JSON).
PAYLOAD=$(cat)
if [ -z "$PAYLOAD" ]; then
  warn "empty stdin, skipping"
  exit 0
fi

SESSION_ID=$(echo "$PAYLOAD" | jq -r '.session_id // empty')
TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // empty')
CWD=$(echo "$PAYLOAD" | jq -r '.cwd // empty')

if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  warn "missing session_id / transcript_path / transcript file, skipping"
  exit 0
fi

CWD="${CWD:-$PWD}"
CWD_ENCODED=$(encode_cwd "$CWD")
PROJECT=$(basename "$CWD")
SHORT_ID="${SESSION_ID:0:8}"

# Resolve output path.
# CLAUDE_PLUGIN_DATA is set by Claude Code in hook context and resolves to
# ~/.claude/plugins/data/<plugin>-<marketplace>/ (auto-namespaced so different
# marketplaces don't collide). Fallback lets manual smoke tests work too.
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/session-log-kratocz}"
LOG_ROOT="$DATA_DIR/logs"
PROJECT_DIR="$LOG_ROOT/$CWD_ENCODED"
if ! mkdir -p "$PROJECT_DIR" 2>/dev/null; then
  warn "cannot create $PROJECT_DIR, skipping"
  exit 0
fi

# Collect metadata.
STARTED=$(jq -r 'select(.timestamp) | .timestamp' "$TRANSCRIPT" 2>/dev/null | head -1)
ENDED=$(jq -r 'select(.timestamp) | .timestamp' "$TRANSCRIPT" 2>/dev/null | tail -1)

if [ -z "$STARTED" ]; then
  warn "no timestamps in transcript, skipping"
  exit 0
fi

DATE=$(date -u -d "$STARTED" +%Y-%m-%d 2>/dev/null || date -u +%Y-%m-%d)
DURATION=$(format_duration "$STARTED" "$ENDED")
TURNS=$(count_turns "$TRANSCRIPT")
GOAL=$(extract_goal "$TRANSCRIPT")
GOAL_YAML=$(yaml_escape "$GOAL")

OUTPUT="$PROJECT_DIR/${DATE}_${SHORT_ID}.md"
TMP="${OUTPUT}.tmp.$$"

# Collapse $HOME to ~ for readability in frontmatter link.
if [[ "$TRANSCRIPT" == "$HOME"/* ]]; then
  TRANSCRIPT_DISPLAY="~${TRANSCRIPT#"$HOME"}"
else
  TRANSCRIPT_DISPLAY="$TRANSCRIPT"
fi

{
  # Frontmatter.
  printf -- '---\n'
  printf 'session_id: %s\n' "$SESSION_ID"
  printf 'project: %s\n' "$PROJECT"
  printf 'cwd: %s\n' "$CWD"
  printf 'started: %s\n' "$STARTED"
  printf 'ended: %s\n' "$ENDED"
  printf 'duration: %s\n' "${DURATION:-unknown}"
  printf 'turns: %s\n' "${TURNS:-0}"
  printf 'transcript: %s\n' "$TRANSCRIPT_DISPLAY"
  printf -- '---\n\n'

  # Title.
  printf '# Session summary — %s (%s)\n\n' "$PROJECT" "$DATE"
  printf '_cwd: %s_\n\n' "$CWD"

  # Goal.
  printf '## Goal\n\n'
  if [ -n "$GOAL" ]; then
    printf '%s\n\n' "$GOAL"
  else
    printf '_(no user message captured)_\n\n'
  fi

  # Files touched.
  printf '## Files touched\n\n'
  files=$(extract_files_touched "$TRANSCRIPT")
  if [ -n "$files" ]; then
    while IFS=$'\t' read -r action path; do
      [ -z "$path" ] && continue
      printf -- '- `%s` (%s)\n' "$path" "$action"
    done <<< "$files"
    printf '\n'
  else
    printf '_(none)_\n\n'
  fi

  # Git commits.
  printf '## Git commits\n\n'
  commits=$(extract_git_commits "$TRANSCRIPT")
  if [ -n "$commits" ]; then
    while IFS= read -r msg; do
      [ -z "$msg" ] && continue
      printf -- '- %s\n' "$msg"
    done <<< "$commits"
    printf '\n'
  else
    printf '_(none)_\n\n'
  fi

  # Tool stats.
  printf '## Tool stats\n\n'
  stats=$(extract_tool_stats "$TRANSCRIPT")
  if [ -n "$stats" ]; then
    printf '%s\n\n' "$stats"
  else
    printf '_(none)_\n\n'
  fi

  # Transcript link.
  printf '## Full transcript\n\n'
  printf 'Raw JSONL: `%s`\n' "$TRANSCRIPT_DISPLAY"
} > "$TMP" 2>/dev/null

if [ -s "$TMP" ] && mv "$TMP" "$OUTPUT" 2>/dev/null; then
  warn "wrote $OUTPUT"
else
  rm -f "$TMP" 2>/dev/null
  warn "failed to write $OUTPUT"
fi

exit 0
