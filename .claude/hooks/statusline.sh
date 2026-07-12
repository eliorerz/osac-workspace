#!/bin/bash
# Project statusline: extends user statusline with osac-workspace + ai-workflows sync status

input=$(cat)

# Run the user's global statusline first
if [[ -f ~/.claude/statusline.sh ]]; then
  echo "$input" | bash ~/.claude/statusline.sh
fi

# Colors
GREEN='\033[32m'
YELLOW='\033[33m'
GRAY='\033[90m'
RESET='\033[0m'

repo_status() {
  local dir="$1" name="$2"
  [[ -d "$dir" ]] || { printf "${GRAY}%s: not found${RESET}" "$name"; return; }

  local behind
  behind=$(git -C "$dir" rev-list HEAD..origin/main --count 2>/dev/null) || { printf "${GRAY}%s: ?${RESET}" "$name"; return; }

  if [[ "$behind" -eq 0 ]]; then
    printf "${GREEN}%s: current${RESET}" "$name"
  else
    printf "${YELLOW}%s: %d behind${RESET}" "$name" "$behind"
  fi
}

WORKSPACE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
AI_DIR="${HOME}/.ai-workflows"

ws=$(repo_status "$WORKSPACE_DIR" "workspace")
ai=$(repo_status "$AI_DIR" "ai-workflows")

printf '%b %b %b\n' "$ws" "${GRAY}|${RESET}" "$ai"
