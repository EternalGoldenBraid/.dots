#!/usr/bin/env python3
"""Generate GitHub or GitHub Enterprise blob URLs for tracked source files."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote, urlparse


def run_git(repo_root: Path, *args: str) -> str:
    """Run a git command in the repository root and return stripped stdout."""
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=repo_root,
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        message = error.stderr.strip() or error.stdout.strip() or "git command failed"
        raise RuntimeError(message) from error
    return result.stdout.strip()


def resolve_ssh_host(host: str) -> str:
    """Resolve an SSH host alias to its configured hostname when possible."""
    if "." in host:
        return host

    result = subprocess.run(
        ["ssh", "-G", host],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return host

    for line in result.stdout.splitlines():
        if line.startswith("hostname "):
            resolved = line.removeprefix("hostname ").strip()
            return resolved or host
    return host


def resolve_repo_root(path: Path) -> Path:
    """Return the git repository root containing the provided path."""
    working_dir = path.parent if path.is_file() else path
    return Path(run_git(working_dir, "rev-parse", "--show-toplevel"))


def ensure_tracked(repo_root: Path, repo_relative_path: Path) -> None:
    """Raise if the path is not tracked by git."""
    run_git(repo_root, "ls-files", "--error-unmatch", repo_relative_path.as_posix())


def ensure_clean(repo_root: Path, repo_relative_path: Path) -> None:
    """Raise if the file differs from HEAD."""
    result = subprocess.run(
        ["git", "diff", "--quiet", "HEAD", "--", repo_relative_path.as_posix()],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode == 1:
        raise RuntimeError(
            f"{repo_relative_path.as_posix()} has local changes. Commit or stash them before generating a source link."
        )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "git diff failed"
        raise RuntimeError(message)


def remote_to_web_url(remote_url: str) -> str:
    """Convert a git remote URL into an HTTPS browser URL."""
    if remote_url.startswith(("http://", "https://")):
        parsed = urlparse(remote_url)
        return f"{parsed.scheme}://{parsed.netloc}{parsed.path.removesuffix('.git')}"

    if remote_url.startswith("ssh://"):
        parsed = urlparse(remote_url)
        if parsed.hostname is None:
            raise RuntimeError(f"Unsupported remote URL: {remote_url}")
        return f"https://{parsed.hostname}{parsed.path.removesuffix('.git')}"

    match = re.fullmatch(r"(?:[^@]+@)?(?P<host>[^:]+):(?P<path>.+?)(?:\.git)?", remote_url)
    if match is None:
        raise RuntimeError(f"Unsupported remote URL: {remote_url}")
    host = resolve_ssh_host(match.group("host"))
    return f"https://{host}/{match.group('path')}"


def resolve_ref(repo_root: Path, explicit_ref: str | None) -> str:
    """Return a remote-visible ref, preferring a HEAD commit permalink."""
    if explicit_ref is not None:
        return explicit_ref

    head_commit = run_git(repo_root, "rev-parse", "HEAD")
    remote_contains_head = run_git(repo_root, "branch", "-r", "--contains", "HEAD")
    if remote_contains_head:
        return head_commit

    raise RuntimeError("HEAD is not known to exist on a fetched remote branch. Push or fetch first, or pass --ref.")


def find_unique_snippet_range(file_text: str, snippet: str) -> tuple[int, int]:
    """Find the unique line range for the provided snippet."""
    offsets: list[int] = []
    offset = file_text.find(snippet)
    while offset != -1:
        offsets.append(offset)
        offset = file_text.find(snippet, offset + 1)

    if not offsets:
        raise RuntimeError("Snippet was not found in the file.")
    if len(offsets) > 1:
        raise RuntimeError("Snippet matched multiple locations. Provide a longer snippet or explicit lines.")

    start_offset = offsets[0]
    end_offset = start_offset + len(snippet)
    start_line = file_text.count("\n", 0, start_offset) + 1
    end_line = file_text.count("\n", 0, end_offset) + 1
    return start_line, end_line


def build_url(base_url: str, ref: str, repo_relative_path: Path, start_line: int | None, end_line: int | None) -> str:
    """Build a GitHub or GHE blob URL with an optional line fragment."""
    encoded_ref = quote(ref, safe="/")
    encoded_path = quote(repo_relative_path.as_posix(), safe="/")
    url = f"{base_url}/blob/{encoded_ref}/{encoded_path}"

    if start_line is None:
        return url
    if end_line is None or end_line == start_line:
        return f"{url}#L{start_line}"
    return f"{url}#L{start_line}-L{end_line}"


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments."""
    parser = argparse.ArgumentParser(description="Generate a GitHub or GHE source URL for a tracked file.")
    parser.add_argument("path", type=Path, help="Path to a tracked file inside a git repository.")
    parser.add_argument("--start-line", type=int, default=None, help="Starting line number.")
    parser.add_argument("--end-line", type=int, default=None, help="Ending line number.")
    parser.add_argument("--snippet", type=str, default=None, help="Unique snippet to locate in the file.")
    parser.add_argument("--snippet-file", type=Path, default=None, help="Read the snippet to locate from a file.")
    parser.add_argument("--stdin-snippet", action="store_true", help="Read the snippet to locate from stdin.")
    parser.add_argument("--ref", type=str, default=None, help="Explicit git ref to use instead of auto detection.")
    parser.add_argument(
        "--format",
        choices=("url", "markdown", "json"),
        default="url",
        help="Output format.",
    )
    parser.add_argument("--label", type=str, default=None, help="Optional link label for markdown output.")
    return parser.parse_args()


def main() -> int:
    """Run the CLI."""
    args = parse_args()
    target_path = args.path.resolve()
    if not target_path.exists():
        raise RuntimeError(f"Path does not exist: {target_path}")

    repo_root = resolve_repo_root(target_path)
    repo_relative_path = target_path.relative_to(repo_root)
    ensure_tracked(repo_root, repo_relative_path)
    ensure_clean(repo_root, repo_relative_path)

    snippet_sources = [args.snippet is not None, args.snippet_file is not None, args.stdin_snippet]
    if sum(snippet_sources) > 1:
        raise RuntimeError("Choose only one snippet source: --snippet, --snippet-file, or --stdin-snippet.")
    if args.end_line is not None and args.start_line is None:
        raise RuntimeError("--end-line requires --start-line.")

    start_line = args.start_line
    end_line = args.end_line
    if any(snippet_sources):
        snippet = args.snippet
        if args.snippet_file is not None:
            snippet = args.snippet_file.read_text()
        elif args.stdin_snippet:
            snippet = sys.stdin.read()
        assert snippet is not None
        file_text = target_path.read_text()
        start_line, end_line = find_unique_snippet_range(file_text, snippet)

    remote_url = run_git(repo_root, "remote", "get-url", "origin")
    base_url = remote_to_web_url(remote_url)
    ref = resolve_ref(repo_root, args.ref)
    url = build_url(base_url, ref, repo_relative_path, start_line, end_line)

    if args.format == "url":
        print(url)
        return 0

    if args.format == "markdown":
        label = args.label or repo_relative_path.as_posix()
        print(f"[{label}]({url})")
        return 0

    payload = {
        "url": url,
        "ref": ref,
        "path": repo_relative_path.as_posix(),
        "start_line": start_line,
        "end_line": end_line,
    }
    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
