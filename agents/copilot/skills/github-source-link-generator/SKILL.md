---
name: github-source-link-generator
description: Generate GitHub or GitHub Enterprise blob URLs for tracked files and line ranges that are visible on the remote. Supports explicit line ranges or snippet lookup via a helper script.
---

# GitHub Source Link Generator

This skill generates clickable source links to code in a Git repository hosted on GitHub or GitHub Enterprise.
It is designed for cases where the target code is already committed and visible on the remote, so the resulting
URL opens directly in the browser.

---

## 1. When to Use This Skill

Use this skill when the user asks for:

- a GitHub link to code
- a permalink to a file or line range
- a clickable source URL for documentation or diagrams
- a browser link for a reviewed snippet
- a GitHub Enterprise URL for tracked local code

This skill is especially useful before embedding links into `.drawio`, Markdown, PR comments, or design docs.

---

## 2. Preconditions

Before generating a link, make sure:

1. the file is tracked by git
2. the code exists in the repository state you want to reference
3. the referenced state is visible on the remote

By default the helper script prefers a **commit permalink** and verifies that `HEAD` is contained in a fetched
remote-tracking branch before using it.

If the file has uncommitted changes, the script fails rather than producing a misleading URL.

---

## 3. URL Format

The canonical format is:

```text
https://<host>/<owner>/<repo>/blob/<ref>/<repo-relative-path>#L<start>-L<end>
```

Examples:

```text
https://github.com/github/awesome-copilot/blob/main/skills/draw-io-diagram-generator/SKILL.md#L1-L20
https://nestai.ghe.com/nestai-internal/ai.cv.trainer/blob/e35d99d/src/cv_trainer/export.py#L111-L121
```

Use a single-line fragment when needed:

```text
#L111
```

---

## 4. Helper Script

Use:

```bash
python skills/github-source-link-generator/scripts/github-source-link.py <path>
```

### Explicit line range

```bash
python skills/github-source-link-generator/scripts/github-source-link.py \
  src/cv_trainer/export.py \
  --start-line 111 \
  --end-line 121
```

### Snippet lookup from an argument

```bash
python skills/github-source-link-generator/scripts/github-source-link.py \
  src/cv_trainer/export.py \
  --snippet "def export_to_onnx("
```

### Snippet lookup from stdin

```bash
printf 'def export_to_onnx(' | python skills/github-source-link-generator/scripts/github-source-link.py \
  src/cv_trainer/export.py \
  --stdin-snippet
```

### JSON output

```bash
python skills/github-source-link-generator/scripts/github-source-link.py \
  src/cv_trainer/export.py \
  --start-line 111 \
  --end-line 121 \
  --format json
```

---

## 5. Workflow

1. Identify the target file.
2. Confirm the file is tracked.
3. Determine the line range directly or locate it from a unique snippet.
4. Generate the URL with the helper script.
5. Prefer the raw URL for tools like draw.io and Markdown links for prose output.

If snippet lookup is ambiguous, do not guess. Narrow the snippet or use explicit line numbers.

---

## 6. Remote URL Rules

The helper supports common remote formats:

- `git@github.com:owner/repo.git`
- `git@host:owner/repo.git`
- `ssh://git@host/owner/repo.git`
- `https://host/owner/repo.git`
- `http://host/owner/repo.git`

SSH remotes are converted to browser URLs using `https://`.

---

## 7. Failure Cases

Fail clearly when:

- the file is not tracked by git
- the file has local modifications relative to `HEAD`
- the snippet does not occur in the file
- the snippet occurs multiple times
- `HEAD` is not known to exist on a fetched remote-tracking branch and no explicit `--ref` is supplied
- the remote URL cannot be converted into a browser URL

---

## 8. Output Variants

The helper script can emit:

- raw URL (`--format url`)
- Markdown link (`--format markdown`)
- JSON (`--format json`)

Use raw URLs for draw.io hyperlink attributes.

---

## 9. Related Use

For clickable code references inside diagrams, use this skill first to generate the URL and then attach that URL to
the relevant draw.io cell.
