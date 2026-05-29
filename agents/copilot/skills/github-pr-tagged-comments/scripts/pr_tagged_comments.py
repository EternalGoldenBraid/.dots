#!/usr/bin/env python3
"""Extract tagged PR review threads and issue comments with stable source permalinks."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import PurePosixPath
from typing import Any
from urllib.parse import quote


def run_gh(*args: str) -> str:
    """Run gh and return stdout."""
    try:
        result = subprocess.run(
            ["gh", *args],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        message = error.stderr.strip() or error.stdout.strip() or "gh command failed"
        raise RuntimeError(message) from error
    return result.stdout


def gh_json(*args: str) -> Any:
    """Run gh and parse JSON output."""
    return json.loads(run_gh(*args))


def gh_paginated_json(*args: str) -> list[Any]:
    """Run gh with pagination and flatten paginated JSON arrays."""
    payload = gh_json("api", "--paginate", "--slurp", *args)
    if not isinstance(payload, list):
        raise RuntimeError("Expected paginated gh api call to return a JSON list.")

    items: list[Any] = []
    for page in payload:
        if isinstance(page, list):
            items.extend(page)
        else:
            items.append(page)
    return items


def parse_repo(repo: str) -> tuple[str, str]:
    """Split owner/repo."""
    parts = repo.split("/", 1)
    if len(parts) != 2 or not all(parts):
        raise RuntimeError(f"Invalid repo '{repo}'. Expected owner/repo.")
    return parts[0], parts[1]


def normalize_body(body: str) -> str:
    """Strip trailing whitespace while preserving internal formatting."""
    return body.replace("\r\n", "\n").strip()


def extract_inline_tag_context(body: str, tag: str) -> str | None:
    """Remove tag markers from a comment body and return any remaining context."""
    lines = normalize_body(body).split("\n")
    cleaned_lines: list[str] = []

    for line in lines:
        stripped = line.strip()
        if not stripped:
            if cleaned_lines and cleaned_lines[-1] != "":
                cleaned_lines.append("")
            continue

        cleaned = stripped.replace(tag, "").strip(" -:\t")
        if cleaned:
            cleaned_lines.append(cleaned)

    while cleaned_lines and cleaned_lines[-1] == "":
        cleaned_lines.pop()

    context = "\n".join(cleaned_lines).strip()
    return context or None


def line_fragment(start_line: int | None, end_line: int | None) -> str:
    """Return a GitHub line fragment."""
    if start_line is None and end_line is None:
        return ""
    if start_line is None:
        start_line = end_line
    if end_line is None:
        end_line = start_line
    if start_line is None:
        return ""
    if end_line == start_line:
        return f"#L{start_line}"
    return f"#L{start_line}-L{end_line}"


def build_source_permalink(
    repo_url: str,
    path: str,
    commit_oid: str | None,
    start_line: int | None,
    end_line: int | None,
) -> str | None:
    """Build a stable blob permalink from comment metadata."""
    if commit_oid is None:
        return None
    encoded_path = quote(PurePosixPath(path).as_posix(), safe="/")
    return (
        f"{repo_url}/blob/{commit_oid}/{encoded_path}"
        f"{line_fragment(start_line=start_line, end_line=end_line)}"
    )


def comment_line_range(comment: dict[str, Any]) -> tuple[int | None, int | None]:
    """Prefer original review line metadata for stable source links."""
    start_line = comment.get("originalStartLine")
    end_line = comment.get("originalLine")
    if start_line is None and end_line is None:
        start_line = comment.get("startLine")
        end_line = comment.get("line")
    if start_line is None:
        start_line = end_line
    if end_line is None:
        end_line = start_line
    return start_line, end_line


@dataclass
class ThreadMatch:
    """One tagged thread match."""

    path: str
    resolved: bool
    outdated: bool
    tag_comment_url: str
    tag_comment_body: str
    context_comment_url: str | None
    context_body: str | None
    source_permalink: str | None
    source_commit: str | None
    source_start_line: int | None
    source_end_line: int | None
    pending_review: bool


def fetch_review_threads(repo: str, pr: int, comment_page_size: int) -> tuple[str, list[dict[str, Any]]]:
    """Fetch all submitted review threads for a PR."""
    owner, repo_name = parse_repo(repo)
    query = """
query($owner:String!, $repo:String!, $pr:Int!, $commentPageSize:Int!, $cursor:String) {
  repository(owner:$owner, name:$repo) {
    url
    pullRequest(number:$pr) {
      reviewThreads(first:100, after:$cursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          isResolved
          isOutdated
          path
          comments(first:$commentPageSize) {
            nodes {
              author { login }
              url
              body
              createdAt
              databaseId
              path
              line
              originalLine
              startLine
              originalStartLine
              commit { oid }
              originalCommit { oid }
            }
          }
        }
      }
    }
  }
}
"""
    cursor: str | None = None
    all_threads: list[dict[str, Any]] = []
    repo_url: str | None = None

    while True:
        args = [
            "api",
            "graphql",
            "-f",
            f"owner={owner}",
            "-f",
            f"repo={repo_name}",
            "-F",
            f"pr={pr}",
            "-F",
            f"commentPageSize={comment_page_size}",
            "-f",
            f"query={query}",
        ]
        if cursor is not None:
            args.extend(["-f", f"cursor={cursor}"])

        payload = gh_json(*args)
        repository = payload["data"]["repository"]
        pull_request = repository["pullRequest"]
        if pull_request is None:
            raise RuntimeError(f"Pull request #{pr} was not found in {repo}.")

        repo_url = repository["url"]
        review_threads = pull_request["reviewThreads"]
        all_threads.extend(review_threads["nodes"])
        if not review_threads["pageInfo"]["hasNextPage"]:
            break
        cursor = review_threads["pageInfo"]["endCursor"]

    if repo_url is None:
        raise RuntimeError(f"Pull request #{pr} was not found in {repo}.")
    return repo_url, all_threads


def normalize_rest_review_comment(comment: dict[str, Any], pending_review: bool) -> dict[str, Any]:
    """Normalize REST review comments to the GraphQL-like shape used by the matcher."""
    commit_oid = comment.get("commit_id")
    original_commit_oid = comment.get("original_commit_id")
    return {
        "author": {"login": ((comment.get("user") or {}).get("login"))},
        "url": comment["html_url"],
        "body": comment.get("body") or "",
        "createdAt": comment.get("created_at"),
        "databaseId": comment["id"],
        "path": comment.get("path"),
        "line": comment.get("line"),
        "originalLine": comment.get("original_line"),
        "startLine": comment.get("start_line"),
        "originalStartLine": comment.get("original_start_line"),
        "commit": {"oid": commit_oid} if commit_oid is not None else None,
        "originalCommit": (
            {"oid": original_commit_oid} if original_commit_oid is not None else None
        ),
        "inReplyToDatabaseId": comment.get("in_reply_to_id"),
        "pendingReview": pending_review,
    }


def build_supplemental_threads(comments: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Build synthetic threads for comments not present in GraphQL reviewThreads."""
    by_root_id: dict[int, list[dict[str, Any]]] = defaultdict(list)

    for comment in comments:
        root_id = comment.get("inReplyToDatabaseId") or comment["databaseId"]
        by_root_id[root_id].append(comment)

    threads: list[dict[str, Any]] = []
    for thread_comments in by_root_id.values():
        thread_comments.sort(
            key=lambda comment: (
                comment.get("createdAt") or "",
                comment["databaseId"],
            )
        )
        threads.append(
            {
                "isResolved": False,
                "isOutdated": False,
                "pendingReview": any(
                    comment.get("pendingReview", False) for comment in thread_comments
                ),
                "path": thread_comments[0].get("path") or "",
                "comments": {"nodes": thread_comments},
            }
        )
    return threads


def fetch_pending_review_comments(repo: str, pr: int) -> list[dict[str, Any]]:
    """Fetch comments from pending PR reviews."""
    reviews = gh_paginated_json(f"repos/{repo}/pulls/{pr}/reviews?per_page=100")
    pending_review_ids = [
        review["id"] for review in reviews if review.get("state") == "PENDING"
    ]

    pending_comments: list[dict[str, Any]] = []
    for review_id in pending_review_ids:
        pending_comments.extend(
            gh_paginated_json(
            f"repos/{repo}/pulls/{pr}/reviews/{review_id}/comments?per_page=100"
        )
        )
    return [
        normalize_rest_review_comment(comment=comment, pending_review=True)
        for comment in pending_comments
    ]


def fetch_additional_review_threads(repo: str, pr: int, known_urls: set[str]) -> list[dict[str, Any]]:
    """Fetch review comments not exposed via GraphQL reviewThreads."""
    submitted_comments = gh_paginated_json(f"repos/{repo}/pulls/{pr}/comments?per_page=100")
    normalized_comments = [
        normalize_rest_review_comment(comment=comment, pending_review=False)
        for comment in submitted_comments
    ]
    normalized_comments.extend(fetch_pending_review_comments(repo=repo, pr=pr))

    supplemental_comments = [
        comment for comment in normalized_comments if comment["url"] not in known_urls
    ]
    return build_supplemental_threads(comments=supplemental_comments)


def find_tagged_review_threads(
    repo: str,
    pr: int,
    author: str,
    tag: str,
    comment_page_size: int,
) -> list[ThreadMatch]:
    """Find exact tagged review-thread matches and their prior context comments."""
    repo_url, threads = fetch_review_threads(repo=repo, pr=pr, comment_page_size=comment_page_size)
    pending_review_urls = {
        comment["url"] for comment in fetch_pending_review_comments(repo=repo, pr=pr)
    }
    for thread in threads:
        thread["pendingReview"] = any(
            comment["url"] in pending_review_urls
            for comment in thread["comments"]["nodes"]
        )
    known_urls = {
        comment["url"]
        for thread in threads
        for comment in thread["comments"]["nodes"]
    }
    threads.extend(fetch_additional_review_threads(repo=repo, pr=pr, known_urls=known_urls))
    matches: list[ThreadMatch] = []

    for thread in threads:
        comments = thread["comments"]["nodes"]
        for index, comment in enumerate(comments):
            if comment["author"] is None or comment["author"]["login"] != author:
                continue
            body = normalize_body(comment["body"])
            if tag not in body:
                continue

            context_comment: dict[str, Any] | None = None
            for previous in reversed(comments[:index]):
                if previous["author"] is None or previous["author"]["login"] != author:
                    continue
                previous_body = normalize_body(previous["body"])
                if tag in previous_body:
                    continue
                context_comment = previous
                break

            inline_context = extract_inline_tag_context(body=body, tag=tag)
            source_comment = context_comment or comment
            source_start_line, source_end_line = comment_line_range(source_comment)
            source_commit = None
            if source_comment.get("originalCommit") is not None:
                source_commit = source_comment["originalCommit"]["oid"]
            elif source_comment.get("commit") is not None:
                source_commit = source_comment["commit"]["oid"]

            matches.append(
                ThreadMatch(
                    path=thread["path"],
                    resolved=thread["isResolved"],
                    outdated=thread["isOutdated"],
                    tag_comment_url=comment["url"],
                    tag_comment_body=body,
                    context_comment_url=(
                        context_comment["url"]
                        if context_comment is not None
                        else (comment["url"] if inline_context is not None else None)
                    ),
                    context_body=(
                        normalize_body(context_comment["body"])
                        if context_comment is not None
                        else inline_context
                    ),
                    source_permalink=build_source_permalink(
                        repo_url=repo_url,
                        path=source_comment["path"],
                        commit_oid=source_commit,
                        start_line=source_start_line,
                        end_line=source_end_line,
                    ),
                    source_commit=source_commit,
                    source_start_line=source_start_line,
                    source_end_line=source_end_line,
                    pending_review=thread.get("pendingReview", False),
                )
            )

    return matches


def format_tagged_review_threads_markdown(matches: list[ThreadMatch]) -> str:
    """Render tagged review matches as markdown."""
    lines: list[str] = []
    for index, match in enumerate(matches, start=1):
        lines.append(f"{index}. `{match.path}`")
        if match.context_body:
            lines.append(f"   - Context: {match.context_body}")
        else:
            lines.append("   - Context: _No earlier same-author context comment found in thread._")
        if match.context_comment_url:
            lines.append(f"   - Context comment: {match.context_comment_url}")
        lines.append(f"   - Tag comment: {match.tag_comment_url}")
        if match.source_permalink:
            lines.append(f"   - Source permalink: {match.source_permalink}")
        lines.append(
            "   - Thread state: "
            f"resolved={str(match.resolved).lower()}, "
            f"outdated={str(match.outdated).lower()}, "
            f"pending_review={str(match.pending_review).lower()}"
        )
    return "\n".join(lines)


def fetch_issue_comments(
    repo: str,
    pr: int,
    author: str | None,
    contains: str | None,
    regex: str | None,
) -> list[dict[str, str]]:
    """Fetch PR issue comments and optionally filter them."""
    comments = gh_json("api", f"repos/{repo}/issues/{pr}/comments?per_page=100")
    results: list[dict[str, str]] = []

    import re

    pattern = re.compile(regex, re.IGNORECASE) if regex is not None else None
    for comment in comments:
        login = ((comment.get("user") or {}).get("login")) or ""
        if author is not None and login != author:
            continue
        body = normalize_body(comment.get("body") or "")
        if contains is not None and contains.lower() not in body.lower():
            continue
        if pattern is not None and pattern.search(body) is None:
            continue
        results.append(
            {
                "author": login,
                "url": comment["html_url"],
                "body": body,
            }
        )
    return results


def format_issue_comments_markdown(comments: list[dict[str, str]]) -> str:
    """Render issue comments as markdown."""
    lines: list[str] = []
    for index, comment in enumerate(comments, start=1):
        lines.append(f"{index}. {comment['url']}")
        lines.append(f"   - Author: {comment['author']}")
        lines.append(f"   - Body: {comment['body']}")
    return "\n".join(lines)


def build_parser() -> argparse.ArgumentParser:
    """Build CLI parser."""
    parser = argparse.ArgumentParser(
        description="Extract tagged GitHub PR review threads and related issue comments."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    tagged_parser = subparsers.add_parser(
        "tagged-review-threads",
        help="Extract exact tagged review-thread comments, including resolved threads.",
    )
    tagged_parser.add_argument("--repo", required=True, help="Repository in owner/repo form.")
    tagged_parser.add_argument("--pr", required=True, type=int, help="Pull request number.")
    tagged_parser.add_argument("--author", required=True, help="GitHub login whose tags to use.")
    tagged_parser.add_argument("--tag", required=True, help="Exact tag text to search for.")
    tagged_parser.add_argument(
        "--comment-page-size",
        default=100,
        type=int,
        help="Number of review-thread comments to request per thread (default: 100).",
    )
    tagged_parser.add_argument(
        "--format",
        choices=("markdown", "json"),
        default="markdown",
        help="Output format.",
    )

    issue_parser = subparsers.add_parser(
        "issue-comments",
        help="Search normal PR issue comments by author and substring or regex.",
    )
    issue_parser.add_argument("--repo", required=True, help="Repository in owner/repo form.")
    issue_parser.add_argument("--pr", required=True, type=int, help="Pull request number.")
    issue_parser.add_argument("--author", help="Filter by GitHub login.")
    issue_parser.add_argument(
        "--contains",
        help="Case-insensitive substring that must appear in the comment body.",
    )
    issue_parser.add_argument(
        "--regex",
        help="Case-insensitive regex that must match the comment body.",
    )
    issue_parser.add_argument(
        "--format",
        choices=("markdown", "json"),
        default="markdown",
        help="Output format.",
    )

    return parser


def main() -> int:
    """Run the CLI."""
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "tagged-review-threads":
        matches = find_tagged_review_threads(
            repo=args.repo,
            pr=args.pr,
            author=args.author,
            tag=args.tag,
            comment_page_size=args.comment_page_size,
        )
        if not matches:
            raise RuntimeError(
                f"No tagged review-thread comments found for author '{args.author}' with tag '{args.tag}'."
            )
        if args.format == "json":
            print(json.dumps([asdict(match) for match in matches], indent=2))
        else:
            print(format_tagged_review_threads_markdown(matches))
        return 0

    comments = fetch_issue_comments(
        repo=args.repo,
        pr=args.pr,
        author=args.author,
        contains=args.contains,
        regex=args.regex,
    )
    if not comments:
        raise RuntimeError("No matching issue comments found.")
    if args.format == "json":
        print(json.dumps(comments, indent=2))
    else:
        print(format_issue_comments_markdown(comments))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
