# project-diary

A Claude Code skill that gives Claude a **persistent, file-based memory of your
project** so context carries across chat sessions. Claude reads the diary before it
acts and writes to it after it does work — so a fresh session already knows what was
built, why, what was decided, and what rules to follow.

It stores three things:

- **Diary** — a dated log of changes, fixes, decisions, plans, and **discussions**
  (the *why* behind the work, complementing git's *what*). Conversations count:
  a stack debate or feature-planning session gets logged even if no files changed —
  git records diffs, but nothing else records the reasoning.
- **Notes** — durable, topic-grouped reference knowledge about the project.
- **Rules & instructions** — standing directives you've given Claude.

## What's in this package

```
.claude/
  skills/project-diary/
    SKILL.md                 # the protocol Claude follows (read/write/search/compact)
    reference/templates.md   # copy-paste templates for every file type
  hooks/
    diary-context.sh         # reminds Claude to search + log on every message
  settings.json              # registers the hook (UserPromptSubmit)
README.md
```

The diary itself (a `diary/` folder) is created **in whatever project you use the
skill in** — it is not part of this package.

## How it works

Two mechanisms work together:

1. **The skill** (`SKILL.md`) holds the full protocol — folder layout, when and how
   to read, how to search, how to write entries, and how to compact indexes so they
   don't bloat. Claude follows it when the work is relevant.
2. **The hook** (`diary-context.sh`) fires on **every message you send** and injects
   a short reminder to (a) consult the diary before acting and (b) log afterward.
   This is the *guarantee* — a skill alone can be silently skipped mid-flow; the hook
   makes the trigger deterministic. It stays completely silent in projects that don't
   have a `diary/` folder, so it's safe to install globally.

### The layout Claude maintains

```
diary/
  index.md                     # top-level summary: active threads, key decisions
  {YYYY}/index.md              # year highlights
    {MM}/index.md              # month highlights (01–12)
      {DD}/index.md            # descriptive daily index: each entry + a paragraph
        {HH-MM}-{slug}.md      # individual entries, e.g. 14-30-add-auth-retry.md
  notes/
    {topic}/index.md           # e.g. notes/auth/ — durable reference, grouped by topic
    {topic}/{slug}.md
  rules-and-instructions/
    {slug}.md                  # one standing rule per file, always in effect
```

**Design choices** (and why):
- Time is `HH-MM`, not `HH:MM` — colons break on some filesystems and in URLs.
- Folders/files are kebab-case for friction-free grep and scripting; the
  human-readable title lives inside each file as a heading.
- Entries are logged **per logical change, not per edit** — one feature is one entry
  even if it took many edits.
- **Indexes are the fast layer**: daily/monthly indexes summarize entries so a new
  session reads a map instead of every file. They're compacted opportunistically
  (when a new day/month starts, or when an index gets long) so they stay useful.

## Installation

### Per project
Copy `.claude/` into the project you want the diary in:

```bash
cp -r /path/to/agent_diary_skill/.claude /path/to/your-project/
```

Then, in a Claude Code session inside that project, say:

> Set up the project diary.

Claude will create the `diary/` scaffold and add a pointer to `CLAUDE.md`.

If the project already has a `.claude/settings.json`, don't overwrite it — merge the
`hooks.UserPromptSubmit` entry from this package's `settings.json` into yours.

### Globally (all projects)
Put the skill and hook in your user-level Claude config so every project can use them:

```bash
cp -r .claude/skills/project-diary ~/.claude/skills/
cp .claude/hooks/diary-context.sh  ~/.claude/hooks/
```

Add the hook to `~/.claude/settings.json` (create the `hooks` block if absent),
pointing at the global copy:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command",
        "command": "$HOME/.claude/hooks/diary-context.sh" } ] }
    ]
  }
}
```

The hook is silent in any project without a `diary/` folder, so nothing happens until
you opt a project in by setting up its diary.

## Usage

Once installed and set up, it's mostly automatic:

- **Just work normally.** After Claude changes code — or after a substantive
  discussion about features, stack, or plans — it logs an entry and updates the
  daily index. When you state a standing preference, it becomes a rule. When it
  learns something durable, it becomes a note.
- **Start of a session**, Claude reads the top index, the latest daily index, and all
  rules — so it's already caught up.
- **When you ask about something**, Claude greps the diary for relevant prior context
  before answering.

Useful things to say:
- "Set up the project diary." — bootstrap `diary/` in a new project.
- "Log this to the diary." — force an entry for the current work.
- "Remember this rule: always run the linter before committing." — creates a rule.
- "What do we know about the auth flow?" — triggers a diary/notes search.
- "Compact the diary indexes." — tidy and summarize the index files.

## Tuning

- **Too many entries?** The skill already says to skip trivial edits and log per
  logical change. If it's still noisy, tell Claude "only log significant changes."
- **Turn off the automatic reminders** but keep the skill: remove the
  `UserPromptSubmit` entry from `settings.json`. Claude will still use the diary when
  relevant, just without the per-message nudge.
- **Change conventions** (folder names, frontmatter fields): edit `SKILL.md` and
  `reference/templates.md`. Keep them in sync — consistency is what makes search and
  compaction reliable.

## Notes and limits

- The hook needs `bash` (present by default on macOS and Linux).
- The diary complements version control; it doesn't replace it. Commit the `diary/`
  folder alongside your code if you want its history shared with your team.
- Claude follows the protocol as instructions, not as an infallible guarantee. The
  hook makes lapses rare, but if you notice a change that didn't get logged, just ask
  Claude to log it.
