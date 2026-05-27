---
name: jira-adf-description-helper
description: Use when converting rough Jira story text into Atlassian Document Format so headings and paragraphs remain editable as separate blocks in Jira.
---

# Jira ADF Description Helper

This skill converts rough plain text into block-structured Atlassian Document Format (ADF) for Jira.

Use it when Jira descriptions created from plain text render visually fine but behave like a single
paragraph block in the web editor.

---

## 1. When to Use This Skill

Use this skill when:

- a Jira description should remain editable section-by-section
- headings in Jira should only affect one section, not the whole description
- you are creating or editing Jira work items through ACLI
- you want a reusable ADF conversion step before `acli jira workitem create` or `edit`

---

## 2. Why This Exists

Passing plain text through ACLI typically produces a single ADF paragraph node containing embedded
newline characters. Jira then renders the text with visible line breaks, but structurally it is
still one block.

That causes rich-text edits like “convert this section to heading” to affect the entire body.

This helper emits separate ADF blocks instead.

---

## 3. Helper Script

Use:

```bash
python skills/jira-adf-description-helper/scripts/plain-text-to-adf.py draft.txt > draft-description.json
```

Then pass the resulting JSON to Jira:

```bash
PAGER=cat acli jira workitem create \
  --project AA \
  --type Story \
  --summary "..." \
  --description-file draft-description.json \
  --json
```

For edits:

```bash
PAGER=cat acli jira workitem edit \
  --key AA-123 \
  --description-file draft-description.json \
  --yes \
  --json
```

---

## 4. Supported Input Conventions

The helper supports:

- blank-line-separated paragraphs
- markdown headings like `## Heading`
- bullet lists using `- item` or `* item`
- ordered lists using `1. item`

Example input:

```text
## What are we trying to do/achieve?
Capture the rough implementation idea.

## Acceptance Criteria
- Story is editable in Jira section by section
- Headings remain separate blocks
```

---

## 5. Output Behavior

The helper emits ADF with separate block nodes:

- `heading`
- `paragraph`
- `bulletList`
- `orderedList`

Within a paragraph block, single line breaks are preserved using `hardBreak`.

