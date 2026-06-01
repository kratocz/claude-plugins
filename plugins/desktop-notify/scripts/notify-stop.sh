#!/usr/bin/env bash
# Fired by Claude Code Stop hook — notifies user that Claude is waiting for a response.
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

PROJECT=$(basename "$PWD")
notify "Claude Code – $PROJECT" "Waiting for your response"
exit 0
