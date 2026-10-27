#!/usr/bin/env python3
"""Automation for the `staging/official` branch.

See docs/architecture/staging-deployment.md for the workflow this implements.

Terminology:
- A *test* is one feature branch's changes merged into `staging/official`
  through one or more PRs. Each PR merge is a first-parent merge commit on
  `staging/official` with GitHub's default subject
  ("Merge pull request #N from owner/branch").
- A test *holds* the files it changed for as long as they differ between
  `staging/official` and `main`. Promotion (plus the sync) or dropping the
  test makes them match `main` again, which releases them.

Only the standard library is used, so this runs on a stock GitHub runner.
Git is called directly; GitHub is called through the `gh` CLI, which reads
GH_TOKEN from the environment.
"""

from __future__ import annotations

import argparse
import datetime as dt
import functools
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from typing import Any, Callable

STAGING_BRANCH = "staging/official"
MAIN_BRANCH = "main"
REMOTE = "origin"
MAIN = f"{REMOTE}/{MAIN_BRANCH}"
STAGING = f"{REMOTE}/{STAGING_BRANCH}"

TEST_MERGE_RE = re.compile(r"^Merge pull request #(\d+) from (\S+)$")
SYNC_SUBJECT = "Sync main into staging/official"
REBUILD_TRAILER = "Re-merged by rebuild-staging"
# Merge subjects that mean a branch contains staging/official history.
STAGING_HISTORY_SUBJECTS = (
    SYNC_SUBJECT,
    "Merge branch 'staging/official'",
    "Merge remote-tracking branch 'origin/staging/official'",
)
PROMOTES_VIA_RE = re.compile(r"Promotes via:\s*#(\d+)", re.IGNORECASE)

GUARDS_CONTEXT = "staging/guards"
GATE_CONTEXT = "staging/gate"
OVERRIDE_LABEL = "staging-check-override"
KEEP_LABEL = "staging-keep"
KEEP_APPROVED_LABEL = "staging-keep-approved"
INCIDENT_LABEL = "staging-sync-failure"
STATUS_LABEL = "staging-official-status"
GATE_WARNING_MARKER = "<!-- staging-gate:warning -->"


def env_int(name: str, default: int) -> int:
    return int(os.environ.get(name) or default)


EXPIRE_DAYS = env_int("STAGING_EXPIRE_DAYS", 21)
NUDGE_BEFORE_DAYS = env_int("STAGING_NUDGE_BEFORE_DAYS", 7)  # day 14 of 21
FINAL_BEFORE_DAYS = env_int("STAGING_FINAL_BEFORE_DAYS", 2)  # day 19 of 21
EXTEND_DAYS = env_int("STAGING_EXTEND_DAYS", 14)
CLOSED_PR_GRACE_DAYS = env_int("STAGING_CLOSED_PR_GRACE_DAYS", 3)
SYNC_GRACE_MINUTES = env_int("STAGING_SYNC_GRACE_MINUTES", 30)
REPING_HOURS = env_int("STAGING_REPING_HOURS", 24)
DROPPED_LOOKBACK_DAYS = env_int("STAGING_DROPPED_LOOKBACK_DAYS", 180)


# --------------------------------------------------------------------------
# git
# --------------------------------------------------------------------------


class GitError(RuntimeError):
    pass


def git(*args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], capture_output=True, text=True, check=False)
    if check and result.returncode != 0:
        raise GitError(f"git {' '.join(args)} failed:\n{result.stderr.strip()}")
    return result.stdout.strip()


def git_ok(*args: str) -> bool:
    return (
        subprocess.run(["git", *args], capture_output=True, check=False).returncode == 0
    )


def lines(text: str) -> list[str]:
    return [line for line in text.splitlines() if line]


def fetch_branches() -> bool:
    """Fetch main and staging/official; return whether staging/official exists.

    Before staging/official is created, it's treated as equal to main (no
    tests), so the guards and the gate still report.
    """
    git(
        "fetch",
        "--no-tags",
        "--prune",
        REMOTE,
        f"+refs/heads/{MAIN_BRANCH}:refs/remotes/{MAIN}",
    )
    if git_ok("ls-remote", "--exit-code", "--heads", REMOTE, STAGING_BRANCH):
        git(
            "fetch",
            "--no-tags",
            REMOTE,
            f"+refs/heads/{STAGING_BRANCH}:refs/remotes/{STAGING}",
        )
        return True
    print(
        f"::notice::{STAGING_BRANCH} doesn't exist yet; treating it as equal to {MAIN_BRANCH}"
    )
    git("update-ref", f"refs/remotes/{STAGING}", f"refs/remotes/{MAIN}")
    return False


def fetch_pr_heads(numbers: list[int]) -> None:
    if numbers:
        git(
            "fetch",
            "--no-tags",
            REMOTE,
            *[f"+refs/pull/{n}/head:refs/remotes/pr/{n}" for n in numbers],
        )


def fetch_commit(sha: str) -> bool:
    return git_ok("cat-file", "-e", f"{sha}^{{commit}}") or git_ok(
        "fetch", "--no-tags", REMOTE, sha
    )


def is_ancestor(ancestor: str, descendant: str) -> bool:
    return git_ok("merge-base", "--is-ancestor", ancestor, descendant)


def changed_files(base: str, head: str) -> set[str]:
    """Files `head` changed since it branched from `base` (three-dot diff)."""
    return set(lines(git("diff", "--name-only", "--no-renames", f"{base}...{head}")))


def differing_files(a: str, b: str, paths: list[str] | None = None) -> set[str]:
    """Files whose content differs between two commits (two-dot diff)."""
    if paths is not None and not paths:
        return set()
    args = ["diff", "--name-only", "--no-renames", a, b]
    if paths:
        args += ["--", *paths]
    return set(lines(git(*args)))


def commit_time(ref: str) -> dt.datetime:
    return dt.datetime.fromtimestamp(
        int(git("log", "-1", "--format=%ct", ref)), dt.timezone.utc
    )


# --------------------------------------------------------------------------
# tests in staging/official
# --------------------------------------------------------------------------


@dataclass
class TestMerge:
    commit: str
    first_parent: str
    head: str
    pr: int
    branch: str  # "owner/branch", as in GitHub's merge subject
    subject: str


@dataclass
class Test:
    branch: str
    merges: list[TestMerge] = field(default_factory=list)
    files: set[str] = field(default_factory=set)
    held: set[str] = field(default_factory=set)

    @property
    def latest(self) -> TestMerge:
        return self.merges[-1]

    @property
    def prs(self) -> list[int]:
        return [m.pr for m in self.merges]

    @property
    def active(self) -> bool:
        return bool(self.held)

    @property
    def head_ref(self) -> str:
        """Branch name without the owner prefix."""
        return self.branch.split("/", 1)[1] if "/" in self.branch else self.branch


def discover_tests(main: str = MAIN, staging: str = STAGING) -> list[Test]:
    """All tests merged into `staging` since it last matched `main`, in merge order."""
    tests: dict[str, Test] = {}
    merge_files: dict[str, set[str]] = {}
    order: dict[str, int] = {}
    log = git(
        "log",
        "--first-parent",
        "--merges",
        "--reverse",
        "--format=%H %P%x09%s",
        f"{main}..{staging}",
    )
    for line in lines(log):
        shas, subject = line.split("\t", 1)
        parts = shas.split()
        if len(parts) != 3:
            continue
        match = TEST_MERGE_RE.match(subject)
        if not match:
            continue  # sync merges and anything else
        commit, first_parent, head = parts
        merge = TestMerge(
            commit=commit,
            first_parent=first_parent,
            head=head,
            pr=int(match.group(1)),
            branch=match.group(2),
            subject=subject,
        )
        test = tests.setdefault(merge.branch, Test(branch=merge.branch))
        test.merges.append(merge)
        merge_files[commit] = changed_files(first_parent, head)
        order[commit] = len(order)
        test.files |= merge_files[commit]

    # Each file belongs to the latest test that changed it. An earlier test
    # that changed the same file was promoted (or its file released) before
    # Guard 3 let the later one in, so it must not count as holding it again.
    owner: dict[str, Test] = {}
    for merge in sorted(
        (m for t in tests.values() for m in t.merges), key=lambda m: order[m.commit]
    ):
        for path in merge_files[merge.commit]:
            owner[path] = tests[merge.branch]
    differing = differing_files(main, staging)
    for test in tests.values():
        test.held = {f for f in test.files & differing if owner.get(f) is test}
    return list(tests.values())


def held_map(tests: list[Test]) -> dict[str, Test]:
    """File -> the active test holding it.

    discover_tests already gives each file to at most one test.
    """
    result: dict[str, Test] = {}
    for test in tests:
        for path in test.held:
            result.setdefault(path, test)
    return result


def staging_first_parent_chain(main: str = MAIN, staging: str = STAGING) -> set[str]:
    return set(lines(git("rev-list", "--first-parent", f"{main}..{staging}")))


# --------------------------------------------------------------------------
# guards for PRs into staging/official (Guards 1-3)
# --------------------------------------------------------------------------


@dataclass
class PullRequest:
    number: int
    head_sha: str
    head_ref: str
    head_owner: str
    labels: set[str]
    body: str
    url: str = ""

    @property
    def branch(self) -> str:
        return f"{self.head_owner}/{self.head_ref}"


@dataclass
class Verdict:
    state: str  # success | pending | failure
    description: str
    files: set[str] = field(default_factory=set)
    waiting_on: Test | None = None


def short_list(paths: set[str] | list[str], limit: int = 3) -> str:
    items = sorted(paths)
    text = ", ".join(items[:limit])
    return text + (f" (+{len(items) - limit} more)" if len(items) > limit else "")


def contains_staging_history(
    head: str, chain: set[str], staging_pr_numbers: set[int]
) -> str | None:
    """Return a reason if `head` contains staging/official history (Guard 2)."""
    for line in lines(git("log", "--format=%H%x09%s", f"{MAIN}..{head}")):
        sha, subject = line.split("\t", 1)
        if sha in chain:
            return f"contains staging/official commit {sha[:8]}"
        if subject.startswith(STAGING_HISTORY_SUBJECTS):
            return f"contains a merge of staging/official ({sha[:8]})"
        match = TEST_MERGE_RE.match(subject)
        if match and int(match.group(1)) in staging_pr_numbers:
            return f"contains staging test merge #{match.group(1)} ({sha[:8]})"
    return None


def evaluate_staging_prs(
    prs: list[PullRequest],
    tests: list[Test],
    staging_pr_numbers: set[int],
) -> dict[int, Verdict]:
    """Guards 1-3 for open PRs into staging/official, oldest PR first.

    A PR that passes reserves its files, so two waiting PRs can't both turn
    green for the same file once it is released.
    """
    holders = held_map(tests)
    chain = staging_first_parent_chain()
    reserved: dict[str, PullRequest] = {}
    verdicts: dict[int, Verdict] = {}
    for pr in sorted(prs, key=lambda p: p.number):
        files = changed_files(MAIN, pr.head_sha)
        iac = {f for f in files if f.startswith("iac/")}
        if iac:
            verdicts[pr.number] = Verdict(
                "failure",
                f"Changes iac/ ({short_list(iac, 2)}); infrastructure goes through main",
                files,
            )
            continue
        history = contains_staging_history(pr.head_sha, chain, staging_pr_numbers)
        if history:
            verdicts[pr.number] = Verdict(
                "failure",
                f"Branch {history}; update from main instead",
                files,
            )
            continue
        blocking_test = next(
            (
                holders[f]
                for f in sorted(files)
                if f in holders and holders[f].branch != pr.branch
            ),
            None,
        )
        if blocking_test:
            overlap = files & blocking_test.held
            verdicts[pr.number] = Verdict(
                "pending",
                f"Waiting on staging test #{blocking_test.latest.pr} ({short_list(overlap, 2)})",
                files,
                waiting_on=blocking_test,
            )
            continue
        blocking_pr = next(
            (
                reserved[f]
                for f in sorted(files)
                if f in reserved and reserved[f].branch != pr.branch
            ),
            None,
        )
        if blocking_pr:
            verdicts[pr.number] = Verdict(
                "pending",
                f"Waiting on #{blocking_pr.number}, which is ready to merge first",
                files,
            )
            continue
        for path in files:
            reserved.setdefault(path, pr)
        verdicts[pr.number] = Verdict("success", "Ready for staging", files)
    return verdicts


# --------------------------------------------------------------------------
# gate for PRs into main (Guard 5)
# --------------------------------------------------------------------------


@dataclass
class StagingPrRecord:
    """A merged PR into staging/official, from the GitHub API."""

    number: int
    head_sha: str
    branch: str
    merged_at: str
    body: str


def dropped_tests_in(
    head: str,
    records: list[StagingPrRecord],
    tests: list[Test],
    merged_into_main: Callable[[str], bool],
) -> list[StagingPrRecord]:
    """Tests that left staging without being promoted and whose commits `head` contains."""
    active_branches = {t.branch for t in tests if t.active}
    latest: dict[str, StagingPrRecord] = {}
    for record in sorted(records, key=lambda r: r.merged_at):
        latest[record.branch] = record
    found = []
    for branch, record in latest.items():
        if branch in active_branches or not fetch_commit(record.head_sha):
            continue
        if not is_ancestor(record.head_sha, head):
            continue
        files = changed_files(MAIN, record.head_sha)
        if files and not differing_files(MAIN, record.head_sha, sorted(files)):
            continue  # main already has this version: promoted
        if merged_into_main(branch):
            continue
        found.append(record)
    return found


def evaluate_main_pr(
    pr: PullRequest,
    tests: list[Test],
    staging_bodies: dict[int, str],
) -> Verdict:
    if OVERRIDE_LABEL in pr.labels:
        return Verdict("success", f"Overridden with {OVERRIDE_LABEL}")
    holders = held_map(tests)
    files = changed_files(MAIN, pr.head_sha)
    if not files:
        return Verdict("success", "No changed files")
    differs = differing_files(STAGING, pr.head_sha, sorted(files))

    tested_files = {f for f in files if f in holders and f not in differs}
    linked = [
        t
        for t in tests
        if t.active
        and (
            t.branch == pr.branch
            or any(
                str(pr.number) in PROMOTES_VIA_RE.findall(staging_bodies.get(n, ""))
                for n in t.prs
            )
        )
    ]
    promoted_tests = {holders[f].latest.pr for f in tested_files} | {
        t.latest.pr for t in linked
    }
    if promoted_tests:
        tests_text = ", ".join(f"#{n}" for n in sorted(promoted_tests))
        if differs:
            return Verdict(
                "failure",
                f"Differs from what was tested in staging ({tests_text}): {short_list(differs, 2)}",
                files,
            )
        return Verdict(
            "success", f"Matches what was tested in staging ({tests_text})", files
        )

    waiting = {f: holders[f] for f in files if f in holders}
    if waiting:
        test = next(iter(waiting.values()))
        return Verdict(
            "pending",
            f"Waiting on staging test #{test.latest.pr} ({short_list(set(waiting), 2)})",
            files,
            waiting_on=test,
        )
    return Verdict("success", "No files under test in staging", files)


def gate_warning(pr: PullRequest, dropped: list[StagingPrRecord]) -> str | None:
    if not dropped:
        return None
    rows = []
    for record in dropped:
        if record.branch == pr.branch:
            rows.append(
                f"- This branch's staging test #{record.number} was removed from staging "
                "without being promoted, so this PR is treated as untested."
            )
        else:
            rows.append(
                f"- This PR includes commits from `{record.branch}`, whose staging test "
                f"#{record.number} was removed from staging without being promoted."
            )
    return (
        f"{GATE_WARNING_MARKER}\n"
        "### ⚠️ Includes code from a dropped staging test\n\n"
        + "\n".join(rows)
        + "\n\nThis doesn't block merging. Make sure the dropped code is intended, "
        "for example by checking why the test was removed."
    )


# --------------------------------------------------------------------------
# GitHub
# --------------------------------------------------------------------------


def repo() -> str:
    return os.environ["GITHUB_REPOSITORY"]


def gh(*args: str, input_text: str | None = None, check: bool = True) -> str:
    result = subprocess.run(
        ["gh", *args], capture_output=True, text=True, input=input_text, check=False
    )
    if check and result.returncode != 0:
        raise RuntimeError(f"gh {' '.join(args)} failed:\n{result.stderr.strip()}")
    return result.stdout


def gh_json(*args: str) -> Any:
    out = gh(*args)
    return json.loads(out) if out.strip() else None


def gh_api(
    method: str, path: str, payload: dict | None = None, check: bool = True
) -> Any:
    args = ["api", "-X", method, path]
    if payload is not None:
        args += ["--input", "-"]
    out = gh(
        *args,
        input_text=json.dumps(payload) if payload is not None else None,
        check=check,
    )
    return json.loads(out) if out.strip() else None


PR_FIELDS = "number,headRefOid,headRefName,headRepositoryOwner,labels,body,url"


def to_pr(raw: dict) -> PullRequest:
    return PullRequest(
        number=raw["number"],
        head_sha=raw["headRefOid"],
        head_ref=raw["headRefName"],
        head_owner=(raw.get("headRepositoryOwner") or {}).get("login", ""),
        labels={label["name"] for label in raw.get("labels", [])},
        body=raw.get("body") or "",
        url=raw.get("url", ""),
    )


def open_prs(base: str) -> list[PullRequest]:
    raw = gh_json(
        "pr",
        "list",
        "--repo",
        repo(),
        "--base",
        base,
        "--state",
        "open",
        "--limit",
        "500",
        "--json",
        PR_FIELDS,
    )
    return [to_pr(r) for r in raw or []]


def merged_staging_prs() -> list[StagingPrRecord]:
    cutoff = (now_utc() - dt.timedelta(days=DROPPED_LOOKBACK_DAYS)).date().isoformat()
    raw = gh_json(
        "pr",
        "list",
        "--repo",
        repo(),
        "--base",
        STAGING_BRANCH,
        "--state",
        "merged",
        "--search",
        f"merged:>={cutoff}",
        "--limit",
        "1000",
        "--json",
        "number,headRefOid,headRefName,headRepositoryOwner,mergedAt,body",
    )
    return [
        StagingPrRecord(
            number=r["number"],
            head_sha=r["headRefOid"],
            branch=f"{(r.get('headRepositoryOwner') or {}).get('login', '')}/{r['headRefName']}",
            merged_at=r["mergedAt"],
            body=r.get("body") or "",
        )
        for r in raw or []
    ]


@functools.cache
def merged_into_main(branch: str) -> bool:
    """Whether this owner/branch has a merged PR into main."""
    return any(r["state"] == "MERGED" for r in main_prs_from(branch))


def main_prs_from(branch: str) -> list[dict]:
    """PRs into main from this owner/branch (`--head` alone ignores the owner)."""
    owner, _, head_ref = branch.partition("/")
    raw = (
        gh_json(
            "pr",
            "list",
            "--repo",
            repo(),
            "--base",
            MAIN_BRANCH,
            "--head",
            head_ref,
            "--state",
            "all",
            "--limit",
            "20",
            "--json",
            "number,state,closedAt,headRepositoryOwner",
        )
        or []
    )
    return [
        r for r in raw if (r.get("headRepositoryOwner") or {}).get("login", "") == owner
    ]


def set_status(sha: str, context: str, verdict: Verdict, target_url: str = "") -> None:
    payload = {
        "state": verdict.state,
        "context": context,
        "description": verdict.description[:140],
    }
    if target_url:
        payload["target_url"] = target_url
    try:
        gh_api("POST", f"repos/{repo()}/statuses/{sha}", payload)
    except RuntimeError as error:  # e.g. read-only tokens on Dependabot runs
        print(f"::warning::Could not set {context} on {sha[:8]}: {error}")


def issue_comments(number: int) -> list[dict]:
    pages = gh_json(
        "api", "--paginate", "--slurp", f"repos/{repo()}/issues/{number}/comments"
    )
    return [c for page in pages or [] for c in page]


def comment(number: int, body: str) -> None:
    gh_api("POST", f"repos/{repo()}/issues/{number}/comments", {"body": body})


def upsert_marked_comment(number: int, marker: str, body: str | None) -> None:
    """Create, update or (with body=None) delete the comment carrying `marker`."""
    existing = next(
        (c for c in issue_comments(number) if marker in (c.get("body") or "")), None
    )
    if body is None:
        if existing:
            gh_api("DELETE", f"repos/{repo()}/issues/comments/{existing['id']}")
    elif existing:
        if existing["body"] != body:
            gh_api(
                "PATCH",
                f"repos/{repo()}/issues/comments/{existing['id']}",
                {"body": body},
            )
    else:
        comment(number, body)


def has_marker(comments: list[dict], marker: str) -> bool:
    return any(marker in (c.get("body") or "") for c in comments)


def remove_label(number: int, label: str) -> bool:
    try:
        gh_api("DELETE", f"repos/{repo()}/issues/{number}/labels/{label}")
        return True
    except RuntimeError as error:
        print(f"::warning::Could not remove {label} from #{number}: {error}")
        return False


def steward_mentions() -> str:
    names = re.split(r"[\s,]+", os.environ.get("STAGING_STEWARD", "").strip())
    return " ".join(f"@{n.lstrip('@')}" for n in names if n)


def steward_logins() -> list[str]:
    return [
        n.lstrip("@")
        for n in re.split(r"[\s,]+", os.environ.get("STAGING_STEWARD", "").strip())
        if n
    ]


def team_mention() -> str:
    team = os.environ.get("STAGING_TEAM", "").strip()
    return f"@{team.lstrip('@')}" if team else ""


def find_issue(label: str, state: str = "open") -> dict | None:
    raw = gh_json(
        "issue",
        "list",
        "--repo",
        repo(),
        "--label",
        label,
        "--state",
        state,
        "--limit",
        "1",
        "--json",
        "number,body,comments,createdAt",
    )
    return raw[0] if raw else None


def run_url() -> str:
    server = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
    run_id = os.environ.get("GITHUB_RUN_ID")
    return f"{server}/{repo()}/actions/runs/{run_id}" if run_id else ""


def now_utc() -> dt.datetime:
    override = os.environ.get("STAGING_NOW")  # for tests
    if override:
        return dt.datetime.fromisoformat(override)
    return dt.datetime.now(dt.timezone.utc)


def parse_time(value: str) -> dt.datetime:
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))


# --------------------------------------------------------------------------
# rebuild, sync and reset
# --------------------------------------------------------------------------


def configure_identity() -> None:
    if not git_ok("config", "user.email"):
        git(
            "config",
            "user.name",
            os.environ.get("GIT_AUTHOR_NAME", "staging-official[bot]"),
        )
        git(
            "config",
            "user.email",
            os.environ.get(
                "GIT_AUTHOR_EMAIL", "staging-official-bot@users.noreply.github.com"
            ),
        )


@dataclass
class RebuildResult:
    kept: list[Test]
    dropped: list[tuple[Test, str]]
    pushed: bool


def rebuild(drop: set[str], reason: str, push: bool = True) -> RebuildResult:
    """Reset staging/official to main and re-merge every active test not in `drop`.

    `drop` holds test branches ("owner/branch"). Tests never share files, so
    re-merging can only conflict with a newer main; such tests are dropped too.
    """
    configure_identity()
    old = git("rev-parse", STAGING)
    tests = [t for t in discover_tests() if t.active]
    git("checkout", "--quiet", "--detach", MAIN)
    kept: list[Test] = []
    dropped: list[tuple[Test, str]] = []
    for test in tests:
        if test.branch in drop:
            dropped.append((test, reason))
            continue
        merge = test.latest
        if git_ok(
            "merge",
            "--no-ff",
            "--quiet",
            merge.head,
            "-m",
            merge.subject,
            "-m",
            REBUILD_TRAILER,
        ):
            kept.append(test)
        else:
            conflicts = lines(git("diff", "--name-only", "--diff-filter=U"))
            git("merge", "--abort")
            dropped.append((test, f"conflicts with main in {short_list(conflicts)}"))
    pushed = False
    if push:
        git(
            "push",
            f"--force-with-lease={STAGING_BRANCH}:{old}",
            REMOTE,
            f"HEAD:refs/heads/{STAGING_BRANCH}",
        )
        pushed = True
        for test, why in dropped:
            notify_dropped(test, why)
    return RebuildResult(kept, dropped, pushed)


def notify_dropped(test: Test, why: str) -> None:
    body = (
        f"🧹 This staging test (`{test.branch}`) was **removed from `staging/official`**: {why}.\n\n"
        f"Staging is back on `main`'s version of: {short_list(test.files, 10)}.\n\n"
        "To test again, update the branch from `main` if needed and open a new PR into "
        "`staging/official`. Clean up anything the test created that `main` doesn't have, "
        "such as tables for new dbt models."
    )
    if run_url():
        body += f"\n\n[Workflow run]({run_url()})"
    comment(test.latest.pr, body)


def sync() -> int:
    """Merge main into staging/official; drop the test holding any conflicting file."""
    configure_identity()
    if is_ancestor(MAIN, STAGING):
        print("staging/official already contains main")
        return 0
    main_sha = git("rev-parse", MAIN)
    if is_ancestor(STAGING, MAIN):
        # Nothing in staging beyond main: fast-forward, no merge commit needed.
        git("push", REMOTE, f"{MAIN}:refs/heads/{STAGING_BRANCH}")
        print(f"Fast-forwarded staging/official to {main_sha[:8]}")
        return 0
    holders = held_map(discover_tests())
    # main changing a held file (only possible with staging-check-override)
    # ends that test even when git could merge both versions: staging would
    # otherwise run a blend nobody tested.
    main_changed = changed_files(STAGING, MAIN)
    overridden = sorted(f for f in main_changed if f in holders)
    if overridden:
        owners = {holders[f].branch for f in overridden}
        result = rebuild(
            owners,
            f"`main` ({main_sha[:8]}) changed {short_list(overridden)}, which this test holds",
        )
        print(
            f"Dropped {', '.join(t.branch for t, _ in result.dropped)}; kept {len(result.kept)} test(s)"
        )
        return 0
    git("checkout", "--quiet", "--detach", STAGING)
    message = f"{SYNC_SUBJECT} ({main_sha[:8]})"
    if git_ok("merge", "--no-ff", "--quiet", MAIN, "-m", message):
        git("push", REMOTE, f"HEAD:refs/heads/{STAGING_BRANCH}")
        print(f"Merged {main_sha[:8]} into staging/official")
        return 0
    conflicts = lines(git("diff", "--name-only", "--diff-filter=U"))
    git("merge", "--abort")
    orphans = [f for f in conflicts if f not in holders]
    if orphans:
        raise_incident(
            f"Sync of `{main_sha[:8]}` conflicts in files no test holds: {short_list(orphans, 10)}. "
            "staging/official has changes that aren't from a test; fix them by hand or reset the branch."
        )
        return 1
    owners = {holders[f].branch for f in conflicts}
    result = rebuild(
        owners,
        f"`main` ({main_sha[:8]}) changed {short_list(conflicts)}, which this test holds",
    )
    print(
        f"Dropped {', '.join(t.branch for t, _ in result.dropped)}; kept {len(result.kept)} test(s)"
    )
    return 0


def reset_if_clean() -> bool:
    """Reset staging/official to main when its content already equals main."""
    if git("rev-parse", STAGING) == git("rev-parse", MAIN):
        return False
    if any(t.active for t in discover_tests()) or differing_files(MAIN, STAGING):
        return False
    old = git("rev-parse", STAGING)
    git(
        "push",
        f"--force-with-lease={STAGING_BRANCH}:{old}",
        REMOTE,
        f"{MAIN}:refs/heads/{STAGING_BRANCH}",
    )
    print("Reset staging/official to main (no content change)")
    return True


# --------------------------------------------------------------------------
# incidents and the status issue
# --------------------------------------------------------------------------


def raise_incident(text: str) -> None:
    issue = find_issue(INCIDENT_LABEL)
    body = text + (f"\n\n[Workflow run]({run_url()})" if run_url() else "")
    if issue:
        comment(issue["number"], body)
        return
    title = "staging/official sync is failing"
    args = [
        "issue",
        "create",
        "--repo",
        repo(),
        "--title",
        title,
        "--label",
        INCIDENT_LABEL,
        "--body",
        f"{body}\n\n{steward_mentions()} {team_mention()}".strip(),
    ]
    for login in steward_logins():
        args += ["--assignee", login]
    gh(*args)


def close_incident_if_resolved() -> None:
    issue = find_issue(INCIDENT_LABEL)
    if issue and is_ancestor(MAIN, STAGING):
        comment(
            issue["number"], "✅ `staging/official` contains `main` again. Closing."
        )
        gh("issue", "close", "--repo", repo(), str(issue["number"]))


def reping_incident() -> None:
    issue = find_issue(INCIDENT_LABEL)
    if not issue:
        return
    times = [parse_time(c["createdAt"]) for c in issue.get("comments", [])] or [
        parse_time(issue["createdAt"])
    ]
    if now_utc() - max(times) > dt.timedelta(hours=REPING_HOURS):
        comment(issue["number"], f"⏰ Still unresolved. {steward_mentions()}")


@dataclass
class TestSchedule:
    test: Test
    merged_at: dt.datetime
    deadline: dt.datetime
    main_pr: int | None
    main_pr_state: str  # open | merged | closed | none


def render_status(
    schedules: list[TestSchedule],
    waiting: dict[str, list[int]],
    expired: list[TestSchedule],
    auto_remove: str,
    orphan_diff: set[str],
) -> str:
    server = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
    compare = f"{server}/{repo()}/compare/{MAIN_BRANCH}...{STAGING_BRANCH}"
    out = [
        "<!-- maintained by staging-monitor.yml; edits are overwritten -->",
        f"_Updated {now_utc():%Y-%m-%d %H:%M} UTC. Compare: [`main...staging/official`]({compare})._",
        "",
    ]
    in_sync = is_ancestor(MAIN, STAGING)
    out.append(
        f"**Sync:** {'✅ contains `main`' if in_sync else '❌ missing `main` commits'}"
    )
    out.append(f"**Automatic removal:** `{auto_remove}`")
    out.append("")
    if schedules:
        out += [
            "| test | branch | in staging since | deadline | PR into main | files held | waiting |",
            "|---|---|---|---|---|---|---|",
        ]
        for s in schedules:
            prs = ", ".join(f"#{n}" for n in s.test.prs)
            main_pr = f"#{s.main_pr} ({s.main_pr_state})" if s.main_pr else "none yet"
            wait = ", ".join(f"#{n}" for n in waiting.get(s.test.branch, [])) or "—"
            out.append(
                f"| {prs} | `{s.test.branch}` | {s.merged_at:%Y-%m-%d} | {s.deadline:%Y-%m-%d} "
                f"| {main_pr} | {short_list(s.test.held, 4)} | {wait} |"
            )
    else:
        out.append("No tests in staging. Staging runs `main`.")
    if expired:
        out += [
            "",
            "**Expired:** "
            + ", ".join(f"#{s.test.latest.pr} (`{s.test.branch}`)" for s in expired),
        ]
        if auto_remove == "dry-run":
            out.append(
                "Dry run: these would have been removed. A steward can run `rebuild-staging` to remove them."
            )
    if orphan_diff:
        out += [
            "",
            f"⚠️ `staging/official` differs from `main` in files no test holds: {short_list(orphan_diff, 10)}",
        ]
    return "\n".join(out)


def update_status_issue(body: str) -> None:
    issue = find_issue(STATUS_LABEL)
    if issue:
        if issue["body"] != body:
            gh("issue", "edit", "--repo", repo(), str(issue["number"]), "--body", body)
        return
    gh(
        "issue",
        "create",
        "--repo",
        repo(),
        "--title",
        "staging/official status",
        "--label",
        STATUS_LABEL,
        "--body",
        body,
    )


# --------------------------------------------------------------------------
# expiry
# --------------------------------------------------------------------------


def find_main_pr(test: Test, staging_bodies: dict[int, str]) -> tuple[int | None, str]:
    linked = [
        int(n)
        for pr in test.prs
        for n in PROMOTES_VIA_RE.findall(staging_bodies.get(pr, ""))
    ]
    candidates = {r["number"]: r for r in main_prs_from(test.branch)}
    for number in linked:
        if number not in candidates:
            view = gh_json(
                "pr",
                "view",
                "--repo",
                repo(),
                str(number),
                "--json",
                "number,state,closedAt",
            )
            if view:
                candidates[number] = view
    if not candidates:
        return None, "none"
    for state in ("OPEN", "MERGED", "CLOSED"):
        for r in sorted(candidates.values(), key=lambda r: -r["number"]):
            if r["state"] == state:
                return r["number"], state.lower()
    return None, "none"


def schedule_for(
    test: Test, staging_bodies: dict[int, str], pr_meta: dict, comments: list[dict]
) -> TestSchedule:
    merged_at = parse_time(pr_meta["mergedAt"])
    deadline = merged_at + dt.timedelta(days=EXPIRE_DAYS)
    for c in comments:
        for until in re.findall(
            r"<!-- staging-monitor:extended-until=(\S+) -->", c.get("body") or ""
        ):
            deadline = max(deadline, parse_time(until))
    main_pr, state = find_main_pr(test, staging_bodies)
    if state == "closed":
        closed = gh_json(
            "pr", "view", "--repo", repo(), str(main_pr), "--json", "closedAt"
        )
        if closed and closed.get("closedAt"):
            deadline = min(
                deadline,
                parse_time(closed["closedAt"])
                + dt.timedelta(days=CLOSED_PR_GRACE_DAYS),
            )
    return TestSchedule(test, merged_at, deadline, main_pr, state)


def process_expiry(
    schedules: list[TestSchedule],
    waiting: dict[str, list[int]],
    pr_meta: dict[int, dict],
    comments_by_pr: dict[int, list[dict]],
) -> list[TestSchedule]:
    """Handle extensions and notices; return the tests past their deadline."""
    now = now_utc()
    expired = []
    for s in schedules:
        pr = s.test.latest.pr
        labels = {label["name"] for label in pr_meta[pr].get("labels", [])}
        comments = comments_by_pr[pr]
        key = f"{s.deadline:%Y-%m-%d}"
        if KEEP_LABEL in labels or KEEP_APPROVED_LABEL in labels:
            blocked_by = waiting.get(s.test.branch, [])
            if blocked_by and KEEP_APPROVED_LABEL not in labels:
                marker = f"<!-- staging-monitor:keep-escalated={key} -->"
                if not has_marker(comments, marker):
                    comment(
                        pr,
                        (
                            f"{marker}\n⏸ An extension was requested, but "
                            f"{', '.join(f'#{n}' for n in blocked_by)} is waiting on this test's files. "
                            f"{steward_mentions()}: add `{KEEP_APPROVED_LABEL}` to grant it."
                        ),
                    )
            # Remove the labels first: if that fails, extending anyway would
            # repeat on every run.
            elif all(
                remove_label(pr, label)
                for label in labels & {KEEP_LABEL, KEEP_APPROVED_LABEL}
            ):
                until = max(now, s.deadline) + dt.timedelta(days=EXTEND_DAYS)
                comment(
                    pr,
                    (
                        f"<!-- staging-monitor:extended-until={until.isoformat()} -->\n"
                        f"⏳ Extended. This test now expires on **{until:%Y-%m-%d}**."
                    ),
                )
                s.deadline = until
                continue
        if now >= s.deadline:
            expired.append(s)
        elif now >= s.deadline - dt.timedelta(days=FINAL_BEFORE_DAYS):
            marker = f"<!-- staging-monitor:final={key} -->"
            if not has_marker(comments, marker):
                comment(
                    pr,
                    (
                        f"{marker}\n⚠️ This staging test will be **removed on {key}**. "
                        f"Add `{KEEP_LABEL}` to extend it by {EXTEND_DAYS} days."
                    ),
                )
        elif now >= s.deadline - dt.timedelta(days=NUDGE_BEFORE_DAYS):
            marker = f"<!-- staging-monitor:nudge={key} -->"
            if not has_marker(comments, marker):
                author = pr_meta[pr].get("author", {}).get("login", "")
                comment(
                    pr,
                    (
                        f"{marker}\n👋 @{author} is this still being tested? It expires on **{key}**. "
                        f"Add `{KEEP_LABEL}` to extend it by {EXTEND_DAYS} days, or promote it with a PR into `main`."
                    ),
                )
    return expired


# --------------------------------------------------------------------------
# commands
# --------------------------------------------------------------------------


def staging_pr_bodies(tests: list[Test]) -> tuple[dict[int, str], dict[int, dict]]:
    bodies: dict[int, str] = {}
    meta: dict[int, dict] = {}
    for test in tests:
        for number in test.prs:
            raw = gh_json(
                "pr",
                "view",
                "--repo",
                repo(),
                str(number),
                "--json",
                "number,body,mergedAt,labels,author",
            )
            bodies[number] = raw.get("body") or ""
            meta[number] = raw
    return bodies, meta


def cmd_guards(_: argparse.Namespace) -> int:
    fetch_branches()
    prs = open_prs(STAGING_BRANCH)
    fetch_pr_heads([p.number for p in prs])
    for pr in prs:
        pr.head_sha = git("rev-parse", f"refs/remotes/pr/{pr.number}")
    tests = discover_tests()
    staging_numbers = {r.number for r in merged_staging_prs()}
    verdicts = evaluate_staging_prs(prs, tests, staging_numbers)
    for pr in prs:
        verdict = verdicts[pr.number]
        print(f"#{pr.number}: {verdict.state} - {verdict.description}")
        set_status(pr.head_sha, GUARDS_CONTEXT, verdict, run_url())
    return 0


def cmd_gate(_: argparse.Namespace) -> int:
    fetch_branches()
    prs = open_prs(MAIN_BRANCH)
    fetch_pr_heads([p.number for p in prs])
    for pr in prs:
        pr.head_sha = git("rev-parse", f"refs/remotes/pr/{pr.number}")
    tests = discover_tests()
    bodies, _meta = staging_pr_bodies([t for t in tests if t.active])
    records = merged_staging_prs()
    for pr in prs:
        verdict = evaluate_main_pr(pr, tests, bodies)
        print(f"#{pr.number}: {verdict.state} - {verdict.description}")
        set_status(pr.head_sha, GATE_CONTEXT, verdict, run_url())
        try:
            warning = gate_warning(
                pr, dropped_tests_in(pr.head_sha, records, tests, merged_into_main)
            )
            upsert_marked_comment(pr.number, GATE_WARNING_MARKER, warning)
        except RuntimeError as error:
            print(f"::warning::Could not update the warning on #{pr.number}: {error}")
    return 0


def cmd_sync(_: argparse.Namespace) -> int:
    if not fetch_branches():
        return 0
    return sync()


def cmd_rebuild(args: argparse.Namespace) -> int:
    if not fetch_branches():
        print(f"::error::{STAGING_BRANCH} doesn't exist")
        return 1
    tests = {t.branch: t for t in discover_tests() if t.active}
    by_pr = {n: t for t in tests.values() for n in t.prs}
    drop: set[str] = set()
    for item in re.split(r"[\s,]+", args.drop.strip()):
        if not item:
            continue
        if item == "all":
            drop |= set(tests)
        elif item.lstrip("#").isdigit() and int(item.lstrip("#")) in by_pr:
            drop.add(by_pr[int(item.lstrip("#"))].branch)
        else:
            print(f"::error::#{item} is not an active staging test")
            return 1
    reason = (
        args.reason
        or f"removed with rebuild-staging by @{os.environ.get('GITHUB_ACTOR', 'unknown')}"
    )
    result = rebuild(drop, reason, push=not args.dry_run)
    for test, why in result.dropped:
        print(f"dropped {test.branch} (#{test.latest.pr}): {why}")
    for test in result.kept:
        print(f"kept {test.branch} (#{test.latest.pr})")
    return 0


def cmd_require_main(_: argparse.Namespace) -> int:
    """Guard 4, run by staging deploy jobs against the checked-out commit."""
    git("fetch", "--no-tags", REMOTE, f"+refs/heads/{MAIN_BRANCH}:refs/remotes/{MAIN}")
    if is_ancestor(MAIN, "HEAD"):
        return 0
    print(
        "::error::This commit doesn't contain origin/main. Deploying it could roll back "
        "main's changes, so staging deploys wait until the sync catches up."
    )
    return 1


def cmd_monitor(args: argparse.Namespace) -> int:
    if not fetch_branches():
        return 0
    now = now_utc()
    # 1. Sync freshness: catches syncs that failed or never ran
    missing = lines(git("rev-list", "--reverse", f"{STAGING}..{MAIN}"))
    if missing and now - commit_time(missing[0]) > dt.timedelta(
        minutes=SYNC_GRACE_MINUTES
    ):
        since = commit_time(missing[0])
        print(f"staging/official has been missing main commits since {since}; syncing")
        if not args.no_push:
            try:
                sync()
            except (GitError, RuntimeError) as error:
                print(f"::error::Sync failed: {error}")
            fetch_branches()
        if not is_ancestor(MAIN, STAGING):
            if find_issue(INCIDENT_LABEL):
                reping_incident()
            else:
                raise_incident(
                    f"`staging/official` has been missing `main` commits since {since:%Y-%m-%d %H:%M} UTC "
                    f"(oldest: `{missing[0][:8]}`), and the monitor's sync attempt didn't fix it. "
                    "Staging deploys are blocked until it catches up. Check the sync workflow runs and the App token."
                )
    if is_ancestor(MAIN, STAGING):
        close_incident_if_resolved()

    # 2. Expiry
    tests = [t for t in discover_tests() if t.active]
    bodies, meta = staging_pr_bodies(tests)
    comments_by_pr = {t.latest.pr: issue_comments(t.latest.pr) for t in tests}
    schedules = [
        schedule_for(t, bodies, meta[t.latest.pr], comments_by_pr[t.latest.pr])
        for t in tests
    ]
    waiting = waiting_map(tests)
    expired = process_expiry(schedules, waiting, meta, comments_by_pr)
    auto_remove = os.environ.get("STAGING_AUTO_REMOVE", "dry-run").strip() or "dry-run"
    if (
        expired
        and auto_remove == "on"
        and is_ancestor(MAIN, STAGING)
        and not args.no_push
    ):
        rebuild(
            {s.test.branch for s in expired},
            f"it expired on {min(s.deadline for s in expired):%Y-%m-%d}",
        )
        fetch_branches()
        schedules = [s for s in schedules if s not in expired]
        expired = []

    # 3. Reset to main once nothing in staging differs from it (trims history; deploys nothing)
    if not args.no_push and reset_if_clean():
        fetch_branches()

    # 4. Status issue
    all_tests = discover_tests()
    orphan = differing_files(MAIN, STAGING) - set(held_map(all_tests))
    update_status_issue(render_status(schedules, waiting, expired, auto_remove, orphan))
    return 0


def waiting_map(tests: list[Test]) -> dict[str, list[int]]:
    """Test branch -> open PRs (into staging/official or main) waiting on its files."""
    holders = held_map(tests)
    result: dict[str, list[int]] = {}
    prs = open_prs(STAGING_BRANCH) + open_prs(MAIN_BRANCH)
    fetch_pr_heads([p.number for p in prs])
    for pr in prs:
        head = f"refs/remotes/pr/{pr.number}"
        files = changed_files(MAIN, head)
        differs = differing_files(STAGING, head, sorted(files))
        for path in files & differs:
            test = holders.get(path)
            if (
                test
                and test.branch != pr.branch
                and pr.number not in result.get(test.branch, [])
            ):
                result.setdefault(test.branch, []).append(pr.number)
    return result


def cmd_incident(args: argparse.Namespace) -> int:
    raise_incident(args.message)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser(
        "guards", help="Set staging/guards on open PRs into staging/official"
    ).set_defaults(func=cmd_guards)
    sub.add_parser("gate", help="Set staging/gate on open PRs into main").set_defaults(
        func=cmd_gate
    )
    sub.add_parser("sync", help="Merge main into staging/official").set_defaults(
        func=cmd_sync
    )
    p = sub.add_parser("rebuild", help="Rebuild staging/official without some tests")
    p.add_argument("--drop", default="", help="Staging PR numbers to drop, or 'all'")
    p.add_argument("--reason", default="")
    p.add_argument("--dry-run", action="store_true")
    p.set_defaults(func=cmd_rebuild)
    sub.add_parser(
        "require-main", help="Fail unless HEAD contains origin/main (Guard 4)"
    ).set_defaults(func=cmd_require_main)
    p = sub.add_parser(
        "monitor", help="Sync freshness, expiry, nightly reset and the status issue"
    )
    p.add_argument(
        "--no-push", action="store_true", help="Never push (removals and resets)"
    )
    p.set_defaults(func=cmd_monitor)
    p = sub.add_parser("incident", help="Open or update the sync incident issue")
    p.add_argument("message")
    p.set_defaults(func=cmd_incident)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
