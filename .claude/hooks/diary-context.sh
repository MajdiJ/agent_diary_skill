#!/usr/bin/env bash
#
# project-diary — UserPromptSubmit hook.
#
# Fires on every user message. If this project uses a diary (diary/ exists), it
# injects a short reminder so Claude reliably (a) consults prior context before
# acting and (b) logs its work afterward. Silent for projects without a diary,
# so it is safe to leave installed everywhere.
#
# stdout from a UserPromptSubmit hook is added to the model's context.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
DIARY="$PROJECT_DIR/diary"

# No diary in this project → stay quiet.
[ -d "$DIARY" ] || exit 0

# Find the newest daily index, if any, to point Claude straight at it.
NEWEST_DAY_INDEX="$(find "$DIARY" -type f -path '*/[0-9][0-9]/index.md' 2>/dev/null | sort | tail -n 1 || true)"
NEWEST_REL="${NEWEST_DAY_INDEX#"$PROJECT_DIR"/}"

cat <<EOF
[project-diary] Diary present — follow the project-diary skill:
- First relevant message this session: read diary/index.md${NEWEST_REL:+, $NEWEST_REL} and diary/rules-and-instructions/.
- Before acting: grep the diary for concrete terms from this message (grep -ril "term" diary/).
  If the previous turn had an unlogged change or discussion, log it now.
- After changes OR substantive discussion (features, stack, plans, decisions — even
  with no file edits): log an entry (per logical change/topic) + update the daily index.
EOF
