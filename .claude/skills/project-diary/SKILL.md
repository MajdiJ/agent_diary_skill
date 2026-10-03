---
name: project-diary
description: Maintain and consult a persistent project diary for cross-session memory. Use at the start of any session and whenever the user sends a message, to search prior context before acting; and after making changes OR having substantive discussions (features, stack/tech choices, plans, decisions), to log what happened and why — even when no files changed. Also covers durable notes and project rules stored under diary/.
---

# Project Diary

A file-based memory for this project. It gives every chat session the context of
the sessions before it: what changed, why, what was decided, and what rules to
follow. You **read** it before acting and **write** to it after doing work.

The diary complements git. Git records *what* changed; the diary records *why*,
what was tried and rejected, and non-code context. Bias entries toward reasoning,
not restating diffs.

## Directory layout

```
diary/
  index.md                        # top-level summary: active threads, key decisions
  {YYYY}/
    index.md                      # the year in brief: monthly highlights
    {MM}/                         # 01–12
      index.md                    # the month: per-entry line + short paragraph
      {DD}/                       # 01–31
        index.md                  # the day: per-entry line + descriptive paragraph
        {HH-MM}-{slug}.md         # one diary entry (24h time, kebab-case slug)
  notes/
    {topic-slug}/                 # semantic grouping: a feature, subsystem, concept
      index.md                    # what this topic is + list of notes
      {slug}.md                   # a durable note
  rules-and-instructions/
    {slug}.md                     # one standing rule or instruction per file
```

Conventions (do not deviate — consistency is what makes search and compaction work):
- Folders and files are **kebab-case**; time is **`HH-MM`** 24-hour (never `:` — it
  breaks on some filesystems and in URLs). Optional seconds: `HH-MM-SS`.
- Zero-pad months and days: `2026/07/01/`, not `2026/7/1/`.
- The human-readable title lives *inside* the file as an `# H1`, not just in the filename.
- Every entry and note starts with the YAML frontmatter block defined in
  `reference/templates.md`. Read that file before writing your first entry.

## When this skill applies

- **Every user message** (a hook reminds you): search the diary for relevant prior
  context before you act. See "Read protocol."
- **After any unit of work** that changes code, docs, config, or the project's
  direction: write a diary entry. See "Write protocol."
- **After any substantive discussion, even if no files changed** — feature ideas,
  stack/library/tech evaluations, architecture debates, plans, scoping, or a
  decision reached in conversation. These are *more* valuable to future sessions
  than diffs (git already records diffs; nothing else records conversations).
- When you learn something durable about the project → a **note**.
- When the user states a standing preference or constraint → a **rule**.

The test for "substantive": would a colleague joining tomorrow act differently for
knowing it? A question you answered from existing docs — no. A comparison of two
libraries where one was ruled out — yes, log it with the reasoning, even if the
final choice is still open.

If `diary/` does not exist yet and the user wants to start using this system,
bootstrap it: create `diary/`, `diary/notes/`, `diary/rules-and-instructions/`,
and a top-level `diary/index.md` from the template. Add a pointer to `CLAUDE.md`
(see "Discoverability") so future sessions know the diary exists.

## Read protocol (before acting)

Do this once per session on the first relevant message, then incrementally after:

1. **Load the standing context** (cheap, always worth it):
   - `diary/index.md`
   - the most recent daily index (`diary/{YYYY}/{MM}/{DD}/index.md`)
   - everything under `diary/rules-and-instructions/` — this folder is small and
     should be treated as always-in-effect.
2. **Search for specifics** in the user's message. Grep the diary for concrete
   nouns — filenames, function names, feature names, error strings, library names:
   ```
   grep -ril "keyword" diary/
   ```
   Search for a few variants (synonyms, the singular/plural, the file's basename).
   Read the entries that match. The indexes handle *indirect* association; grep is
   for *concrete* terms — don't try to grep vibes.
3. **Follow `related:` links** in any entry you open, one hop, if they look relevant.

Keep it bounded: standing context + a handful of targeted greps. Don't read the
whole diary.

## Write protocol (after work or discussion)

**Granularity — log per logical change, not per edit.** A feature is one entry even
if it took fifteen edits and several hours. Open a new entry for: a distinct
feature, a bug fix, a decision, a change of direction, a substantive discussion, or
an abandoned approach worth remembering. If you're still working the same thread,
**append to the open entry** rather than creating a new one.

**Conversations count as work.** When a turn produced a decision, a plan, a tech
evaluation, or a meaningful shift in thinking — log it (`type: discussion`,
`decision`, or `plan`) even though no files changed. Capture what a colleague would
want from the meeting they missed: the options on the table, who preferred what,
what was ruled out and why, and what's still open. Don't wait for the discussion to
"finish" across sessions — log the state reached this session; a later entry can
supersede it (link it via `related:`).

**Catch-up.** When the per-message reminder fires, check: did the *previous* turn
include an unlogged change or substantive discussion? If so, log it now, before
handling the new message. This is the safety net for turns that ended mid-flow.

To write an entry:

1. Create `diary/{YYYY}/{MM}/{DD}/{HH-MM}-{slug}.md` from the entry template. Use
   the current date/time. Create missing `{YYYY}/{MM}/{DD}/` folders as needed.
2. Fill the frontmatter: `title`, `date`, `time`, `type`, `files`, `related`, `tags`.
3. Write the body: what changed or was discussed, **why**, alternatives considered,
   gotchas, and anything a future session would need to not repeat your mistakes.
4. **Update the daily index** (`{DD}/index.md`): add a line
   `- HH-MM — [Title](HH-MM-slug.md) — one-sentence summary` plus a short paragraph
   if the change is significant.
5. If the change is significant at a higher level, update the **monthly** and
   **top-level** indexes too. Most entries only touch the daily index — but
   `decision` and `plan` entries almost always belong in the top-level index's
   **Key decisions** / **Active threads**, since those are what future sessions
   read first. Keep Active threads current: add new threads, and remove or mark
   threads that finished.

Then, as warranted:
- If you learned something durable (an architecture fact, a quirk, an integration
  detail) → add/update a **note** under `diary/notes/{topic-slug}/`.
- If the user gave a standing instruction ("always run X before Y", "never touch Z")
  → add a **rule** under `diary/rules-and-instructions/`.

Don't over-log: skip trivial edits (typos, formatting) unless they carry a decision.
One good entry per real change beats ten noisy ones.

## Notes

Durable, non-chronological knowledge — the reference layer. Group by **semantic
topic**, not by date: `diary/notes/auth/`, `diary/notes/build-pipeline/`. Each topic
folder has an `index.md` describing the topic and listing its notes. When a fact
changes, **edit the existing note** rather than appending a contradicting one.
Cross-link notes and entries with `[[slug]]` or `related:` frontmatter.

## Rules and instructions

`diary/rules-and-instructions/` holds standing directives from the user — one per
file, short, imperative. These are always in effect; the read protocol loads all of
them each session. When a rule is superseded, edit or delete it; don't leave stale
rules to contradict new ones.

## Index maintenance and compaction

Indexes are the high-value, low-cost layer — keep them useful and bounded.

- **Daily / monthly indexes are descriptive**: each lists its entries with time,
  title, and a paragraph. This is what a future session reads instead of every entry.
- **Compaction is opportunistic** (nothing runs between sessions). When you write the
  first entry of a **new day**, glance at yesterday's daily index; if it has grown
  long, summarize its entries into a tighter form and roll the highlights up into the
  monthly index. Same idea at month/year boundaries.
- **Size guardrail**: if any index exceeds ~150 lines, compact the oldest material —
  merge or summarize entries, keeping decisions and open threads, dropping routine
  detail. The individual entry files stay as the full record; the index is a map.

## Discoverability

A fresh session only knows the diary exists if something tells it. Ensure `CLAUDE.md`
(create it if absent) contains a pointer such as:

> This project uses a diary for cross-session context. At session start, read
> `diary/index.md`, the newest daily index, and `diary/rules-and-instructions/`.
> After changes, log an entry per the `project-diary` skill.

The hook in `.claude/settings.json` reinforces this each turn, but the CLAUDE.md
pointer is the durable anchor.
