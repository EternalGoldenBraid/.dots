---
name: agent-handoff-context
description: Use when creating an agent handoff, context file, continuation note, or execution brief for another agent to continue work.
---

# Agent Handoff Context

Write handoff/context files as a **minimal execution brief**, not as a narrative summary.

---

## 1. When to Use This Skill

Use this skill when creating or updating artifacts such as:

- agent handoff notes
- context files
- continuation notes
- execution briefs
- "drop context for another agent" notes

Typical trigger phrases:

- "create a handoff"
- "drop them a context"
- "write agent context"
- "leave notes for another agent"
- "create a continuation note"

---

## 2. Core Rule

Include only what the next agent needs to act correctly on the **next turn**.

Prefer:

- current scope
- current branch / worktree / repo
- active files and paths
- current artifact state
- active workflow constraints
- immediate open question, if one exists

Exclude unless directly required for the next action:

- historical rationale
- story-like retellings of how the work evolved
- resolved mistakes or corrections
- adjacent side threads
- speculative future steps
- tooling commentary

Short version:

> Do not write a mini-retrospective. Write a continuation point.

---

## 3. Recommended Structure

1. **Scope** — what this handoff is for
2. **Current artifacts** — exact files, branch, paths, commit if relevant
3. **Current state** — what exists right now
4. **Working rules** — constraints for continuing safely
5. **Immediate next action** — only if already known and active

---

## 4. Writing Guidance

- Prefer concrete facts over explanation
- Prefer present state over history
- Keep it short enough that another agent can scan it quickly
- If a fact does not change the next agent's behavior, leave it out
- If the user has already chosen a workflow, record the chosen workflow and omit the alternatives

---

## 5. Example

Too much:

- why the team changed from Mermaid to draw.io
- what failed in earlier attempts
- what other related Jira stories might matter later

Good handoff:

- Proposal A draw.io is the source of truth
- current file path
- current branch
- current diagram contains nodes X, Y, Z
- continue with one small diagram edit per commit

