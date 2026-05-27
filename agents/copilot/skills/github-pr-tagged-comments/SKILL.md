---
name: github-pr-tagged-comments
description: Use when extracting exact tagged GitHub PR review comments, especially resolved review threads, and turning them into follow-up story inputs with stable source permalinks.
---

# GitHub PR Tagged Comments

This skill extracts exact marker-tagged PR review comments from GitHub or GitHub Enterprise,
including comments inside resolved review threads that do not show up reliably in regular PR
comment views.

It is designed for workflows where you leave a lightweight marker such as
`<ai.cv.tracker update>` in PR review threads and later want Copilot to collect those tagged
threads into a Jira story draft, backlog note, or refactoring follow-up.

---

## 1. When to Use This Skill

Use this skill when you need to:

- collect PR review comments marked with an exact tag
- search resolved / closed review threads
- extract the original thread context behind a marker comment
- generate stable source permalinks to the reviewed code lines
- turn tagged review findings into story drafts or backlog inputs

Typical trigger phrases:

- "find my `<tag>` comments in this PR"
- "collect the resolved review comments I tagged"
- "extract all `<ai.cv.tracker update>` items"
- "build a story from my tagged PR comments"

---

## 2. Why This Skill Exists

Normal REST comment listing can miss the important context because:

- the marker comment may live in a **resolved review thread**
- the marker itself often contains no useful content beyond the tag
- the real action point is usually the **preceding comment in the same thread**
- direct discussion links can be flaky to reopen later

This skill solves that by:

1. querying **review threads** through GraphQL
2. locating marker comments by exact tag
3. finding the nearest earlier context comment in the same thread
4. generating a **commit permalink** to the reviewed source lines

---

## 3. Helper Script

Use:

```bash
python skills/github-pr-tagged-comments/scripts/pr_tagged_comments.py tagged-review-threads \
  --repo nestai-internal/nestos.edge.uxv.object-recognition-and-tracking-module \
  --pr 37 \
  --author nicklas-fianda \
  --tag '<ai.cv.tracker update>'
```

This returns the tagged review-thread matches with:

- thread resolved/outdated state
- marker comment URL
- nearest prior context comment by the same author
- stable blob permalink to the reviewed code lines

### JSON output

```bash
python skills/github-pr-tagged-comments/scripts/pr_tagged_comments.py tagged-review-threads \
  --repo nestai-internal/nestos.edge.uxv.object-recognition-and-tracking-module \
  --pr 37 \
  --author nicklas-fianda \
  --tag '<ai.cv.tracker update>' \
  --format json
```

### Markdown output

```bash
python skills/github-pr-tagged-comments/scripts/pr_tagged_comments.py tagged-review-threads \
  --repo nestai-internal/nestos.edge.uxv.object-recognition-and-tracking-module \
  --pr 37 \
  --author nicklas-fianda \
  --tag '<ai.cv.tracker update>' \
  --format markdown
```

### Search issue comments for architectural context

Use this when the important context is not a review-thread tag, but a normal PR issue comment.

```bash
python skills/github-pr-tagged-comments/scripts/pr_tagged_comments.py issue-comments \
  --repo nestai-internal/nestos.edge.uxv.object-recognition-and-tracking-module \
  --pr 37 \
  --author nicklas-fianda \
  --contains 'authoritative local filter'
```

---

## 4. Workflow

### A. Collect tagged review-thread follow-ups

1. Identify the repository and PR number.
2. Provide the exact tag string, including angle brackets if used.
3. Provide the author login whose tags should be trusted.
4. Run `tagged-review-threads`.
5. Use the extracted context comments as the story inputs.

### B. Add surrounding architectural context

1. Run `issue-comments` with a meaningful substring or regex.
2. Add those comments as context links, not as separate tagged action points.

### C. Draft the story

For each tagged review-thread item, prefer:

- the **context comment body**
- the **review-thread discussion URL**
- the **source permalink**

This gives you both the original review discussion and a stable code reference even if the review
thread link becomes awkward to reopen.

---

## 5. Output Semantics

For `tagged-review-threads`, each match includes:

- `path` — reviewed file path
- `resolved` / `outdated` — thread state
- `tag_comment_url` — marker comment URL
- `context_comment_url` — earlier thread comment that contains the real note
- `context_body` — actual action point text
- `source_permalink` — commit permalink to the reviewed code lines

The `source_permalink` is built from the review comment's original commit and original line range,
so it stays stable even if the PR branch later changes.

---

## 6. Guidance on Tagging

To make extraction reliable:

- use an **exact marker string**, e.g. `<ai.cv.tracker update>`
- leave the marker as a **separate follow-up comment** in the same review thread
- keep the actual action point in the earlier comment in that same thread
- use one consistent tag per backlog bucket or follow-up category

Good pattern:

```text
This should move into the filter abstraction later.
```

followed by:

```text
<ai.cv.tracker update>

_Tagging for copilot_
```

---

## 7. Failure Cases

Fail clearly when:

- the repository or PR cannot be accessed
- the tag is not found in any review thread
- the author has no matching tagged comments
- a tagged thread has no earlier context comment by that author

If no earlier context comment exists, do not guess. Return the tag hit and note that the context
needs manual inspection.

