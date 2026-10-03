# Templates

Copy these verbatim and fill them in. Keep the frontmatter keys and order
consistent across every file — grep and compaction depend on it.

---

## Diary entry — `diary/{YYYY}/{MM}/{DD}/{HH-MM}-{slug}.md`

```markdown
---
title: Add retry with backoff to the auth client
date: 2026-07-01
time: "14:30"
type: change            # change | fix | decision | discussion | plan | direction | note
files:                  # paths this entry touched (omit if none)
  - src/auth/client.ts
related:                 # links to other entries/notes, repo-relative (optional)
  - diary/2026/06/28/1100-introduce-auth-client.md
tags: [auth, resilience]
---

# Add retry with backoff to the auth client

**What changed.** The auth client now retries transient 5xx/network failures up to
3 times with exponential backoff (200ms base, jitter).

**Why.** Login was failing intermittently against the staging IdP under load; the
failures were transient. Retrying at the client boundary fixes it without touching
callers.

**Alternatives considered.** A gateway-level retry (rejected: would also retry
non-idempotent calls); raising the timeout (rejected: masks the problem, hurts UX).

**Gotchas / follow-ups.** Retries are disabled for the token-exchange call because
it is not idempotent. If we add refresh-token rotation, revisit this.
```

`type` values:
- `change` — code/config/docs changed.
- `fix` — a bug fix (note the root cause).
- `decision` — a choice was made (record the options and the reasoning).
- `discussion` — a substantive conversation with no (or not-yet) decision: feature
  ideas, stack/tech evaluations, trade-off debates. Record the options, arguments,
  what was ruled out, and what's still open. **No files changed is normal here.**
- `plan` — an intended course of action: steps, scope, sequencing. Update or
  supersede (via `related:`) as the plan evolves.
- `direction` — the project's plan/scope shifted.
- `note` — an observation logged chronologically (usually promote to a real note).

### Example: a discussion entry (no files changed)

```markdown
---
title: Database choice — SQLite vs Postgres
date: 2026-07-02
time: "10:05"
type: discussion
related: []
tags: [stack, database]
---

# Database choice — SQLite vs Postgres

**Context.** Deciding the datastore before building the persistence layer.

**Options discussed.** SQLite (zero-ops, file-based, fits single-user desktop use)
vs Postgres (concurrent writers, richer types, but needs a running server).

**Leaning / ruled out.** Ruled out Postgres for v1 — the app is local-first and
single-user; operating a server contradicts the "no setup" goal. SQLite favored.

**Still open.** Whether to use an ORM (drizzle discussed, no decision). Revisit if
multi-device sync lands on the roadmap — that changes the calculus entirely.
```

---

## Daily index — `diary/{YYYY}/{MM}/{DD}/index.md`

```markdown
# 2026-07-01 (Wednesday)

## Summary
Focused on auth resilience. Shipped client-side retry; decided against gateway
retries. Open thread: refresh-token rotation still pending.

## Entries
- 14-30 — [Add retry with backoff to the auth client](14-30-add-retry-with-backoff-to-the-auth-client.md)
  Client now retries transient failures with exponential backoff. Token exchange
  excluded because it is not idempotent.
- 09-15 — [Introduce structured logging](09-15-introduce-structured-logging.md)
  Swapped console logs for the pino logger across the auth module; request IDs now
  propagate through the client.
```

---

## Monthly index — `diary/{YYYY}/{MM}/index.md`

```markdown
# July 2026

## Highlights
- Auth resilience work: client-side retry shipped, structured logging added.
- Decision: no gateway-level retries (idempotency risk).

## Days
- [01](01/index.md) — auth retry + structured logging
- [02](02/index.md) — ...
```

---

## Year index — `diary/{YYYY}/index.md`

```markdown
# 2026

## Highlights
- Q3: auth subsystem hardened (retry, logging, IdP migration).

## Months
- [07 — July](07/index.md) — auth resilience
- [06 — June](06/index.md) — initial auth client
```

---

## Top-level index — `diary/index.md`

```markdown
# Project Diary

Cross-session memory for this project. Read this, the newest daily index, and
everything under `rules-and-instructions/` at the start of a session.

## Active threads
- Auth resilience — retry done; refresh-token rotation pending.

## Key decisions
- 2026-07-01: No gateway-level retries; retry at the client boundary only.

## Map
- [Years](.) — chronological entries (see `{YYYY}/index.md`)
- [notes/](notes/) — durable, topic-grouped knowledge
- [rules-and-instructions/](rules-and-instructions/) — standing directives
```

---

## Note — `diary/notes/{topic-slug}/{slug}.md`

```markdown
---
title: How the auth client talks to the IdP
topic: auth
updated: 2026-07-01
related:
  - diary/2026/07/01/14-30-add-retry-with-backoff-to-the-auth-client.md
tags: [auth, idp]
---

# How the auth client talks to the IdP

Durable reference (edit in place when it changes; don't append contradictions).

- Endpoint: `POST /oauth/token` at `$IDP_BASE_URL`.
- Token exchange is **not idempotent** — never retry it.
- Access tokens live 15 min; there is no refresh rotation yet.
```

## Note topic index — `diary/notes/{topic-slug}/index.md`

```markdown
# auth

Everything about authentication: the client, IdP integration, token handling.

## Notes
- [How the auth client talks to the IdP](how-the-auth-client-talks-to-the-idp.md)
```

---

## Rule — `diary/rules-and-instructions/{slug}.md`

```markdown
---
title: Never retry the token-exchange call
added: 2026-07-01
tags: [auth]
---

# Never retry the token-exchange call

The IdP token exchange is not idempotent. Retrying can double-spend the auth code
and lock the account. Applies to all auth code paths.
```
