---
name: linear-ticket-flow
description: Keep the Linear ticket for the current task moving through its workflow while we work — In Progress when work starts, In Review when the PR is opened, Done when it is merged or the user says it is finished. Use whenever a Linear issue key (RXL-123, SEIF-4, any ABC-123) or a linear.app URL appears in the request, when the user says "ticket" or "issue" about the task at hand, or when starting a code change with no ticket mentioned (ask once). Silently inapplicable when no Linear MCP tools are available.
---

# linear-ticket-flow

The ticket's state should mirror what is actually happening to the code. Move
it forward at three moments, never backward, and say in one line each time.

## 0. Is Linear available?

Check for `mcp__linear-server__save_issue` (ToolSearch `select:` if deferred).
If no Linear tools exist in this session, this skill does not apply: do not
mention it, do not ask for a ticket.

## 1. Find the ticket

- Look in the request for an issue key (`[A-Z][A-Z0-9]+-[0-9]+`) or a
  `linear.app/.../issue/<KEY>` URL. Also accept a key in the current branch
  name (`rxl-132/<slug>`, or Linear's generated `shef-3-<slug>`).
- Found → `get_issue` with fields `status`, `statusType`, `url`, `gitBranchName`,
  `title`. Keep the key for the whole session.
- Not found, and the task is a code change (not a question, review or
  explanation) → ask **once**, in the first reply, without blocking: start the
  work and end the message with "Linear ticket for this? (key, or `none`)".
  `none` or no answer → never ask again this session.

## 1b. Branch for the ticket

When work on a ticket needs a new branch, use the issue's `gitBranchName` from
`get_issue` as-is, branched from `origin/main`. The workspace format is
`identifier-title`, e.g. SHEF-3 → `shef-3-maestro-skeleton-improvements-first-working-pane-server-stop`.
Do not invent a shorter name: the key in the branch name is what lets Linear
link the PR to the issue.

## 2. Transitions

Resolve state names per team with `list_issue_statuses(team)`; match by
`type` first, then name. Typical (RXL): Backlog / Todo (`backlog`,
`unstarted`) → **In Progress** → **In Review** (both `started`) → **Done**
(`completed`). If a team has no review-type state, skip that step.

| moment | condition | action |
|---|---|---|
| work starts | first edit, test run or investigation for the ticket, and current state is `backlog` or `unstarted` | `save_issue(id, state: "In Progress")`; if unassigned, `assignee: "me"` |
| PR opened | `gh pr create` / Bitbucket PR / user shares the PR URL | `save_issue(id, state: "In Review", links: [{url: <PR URL>, title: "PR #N: <title>"}])` |
| finished | PR merged (observed via `gh pr view --json state`, or the user says merged / done / finished / closed) | `save_issue(id, state: "Done")` |

Rules:

- Never move backwards, never reopen, never touch `completed`, `canceled` or
  `duplicate` issues; just report the state you found.
- A ticket already in a later state than the moment implies stays where it is.
- Done only on confirmed merge or the user's word, not because the PR exists.
- Several tickets in one task: apply the same rules to each; the PR link goes
  on all of them.
- Do not edit the ticket body or comments from this skill; status, assignee
  and the PR link only. Content changes follow the user's ticket rules.

## 3. Report

One line per transition in the message where it happened, e.g.
`RXL-140: Todo → In Progress`, `RXL-140: In Progress → In Review (PR #12 attached)`.
If a transition fails (permission, unknown state), say so once and continue
the actual work; the ticket is bookkeeping, not the deliverable.
