"""Tests for staging_official.py against real git repositories.

Run from the repository root:

    python3 -m pytest .github/scripts/tests
"""

import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import staging_official as so  # noqa: E402  # pyright: ignore[reportMissingImports]


def run(cwd, *args):
    return subprocess.run(
        args, cwd=cwd, check=True, capture_output=True, text=True
    ).stdout.strip()


class Repo:
    """A bare `origin` plus a working clone, laid out like GitHub."""

    def __init__(self, root: Path):
        self.origin = root / "origin.git"
        self.work = root / "work"
        run(root, "git", "init", "--quiet", "--bare", "-b", "main", str(self.origin))
        run(root, "git", "clone", "--quiet", str(self.origin), str(self.work))
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.com")
        self.write({"README.md": "hello\n", "airflow/dags/a.py": "a = 1\n"})
        self.commit("initial")
        self.git("push", "--quiet", "origin", "HEAD:main")
        self.git("push", "--quiet", "origin", "HEAD:staging/official")
        self.pr_counter = 100
        self.comments: list = []
        self.incidents: list = []

    def git(self, *args):
        return run(self.work, "git", *args)

    def write(self, files: dict):
        for path, content in files.items():
            target = self.work / path
            if content is None:
                target.unlink()
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content)
        self.git("add", "-A")

    def commit(self, message):
        self.git("commit", "--quiet", "-m", message)
        return self.git("rev-parse", "HEAD")

    def branch(self, name, files, base="origin/main"):
        """Create a feature branch with one commit; return its head SHA."""
        self.git("fetch", "--quiet", "origin")
        self.git("checkout", "--quiet", "-B", name, base)
        self.write(files)
        sha = self.commit(f"change on {name}")
        self.git("push", "--quiet", "--force", "origin", f"HEAD:refs/heads/{name}")
        return sha

    def merge_into_staging(self, branch, head):
        """Merge like GitHub's merge button; return the PR number."""
        self.pr_counter += 1
        self.git("fetch", "--quiet", "origin")
        self.git("checkout", "--quiet", "--detach", "origin/staging/official")
        self.git(
            "merge",
            "--quiet",
            "--no-ff",
            head,
            "-m",
            f"Merge pull request #{self.pr_counter} from cal-itp/{branch}",
        )
        self.git("push", "--quiet", "origin", "HEAD:refs/heads/staging/official")
        return self.pr_counter

    def squash_into_main(self, files, message="squash"):
        self.git("fetch", "--quiet", "origin")
        self.git("checkout", "--quiet", "--detach", "origin/main")
        self.write(files)
        sha = self.commit(message)
        self.git("push", "--quiet", "origin", "HEAD:refs/heads/main")
        return sha

    def refresh(self):
        so.fetch_branches()

    def show(self, ref, path):
        return self.git("show", f"{ref}:{path}")


@pytest.fixture
def repo(tmp_path, monkeypatch):
    r = Repo(tmp_path)
    monkeypatch.chdir(r.work)
    monkeypatch.setenv("GITHUB_REPOSITORY", "cal-itp/data-infra")
    monkeypatch.setattr(so, "comment", lambda n, body: r.comments.append((n, body)))
    monkeypatch.setattr(so, "raise_incident", lambda text: r.incidents.append(text))
    return r


def pr(number, branch, head):
    return so.PullRequest(
        number=number,
        head_sha=head,
        head_ref=branch,
        head_owner="cal-itp",
        labels=set(),
        body="",
    )


# ---------------------------------------------------------------- discovery


def test_discovers_tests_and_held_files(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    pr_a = repo.merge_into_staging("feature/a", a)
    b = repo.branch("feature/b", {"warehouse/models/b.sql": "select 1\n"})
    repo.merge_into_staging("feature/b", b)
    repo.refresh()

    tests = so.discover_tests()

    assert [t.branch for t in tests] == ["cal-itp/feature/a", "cal-itp/feature/b"]
    assert tests[0].held == {"airflow/dags/a.py"}
    assert tests[0].latest.pr == pr_a
    assert tests[1].held == {"warehouse/models/b.sql"}


def test_update_from_same_branch_is_one_test(repo):
    a1 = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a1)
    repo.git("checkout", "--quiet", "feature/a")
    repo.write({"airflow/dags/a2.py": "x\n"})
    a2 = repo.commit("more")
    repo.git("push", "--quiet", "origin", "HEAD:refs/heads/feature/a")
    repo.merge_into_staging("feature/a", a2)
    repo.refresh()

    (test,) = so.discover_tests()

    assert len(test.merges) == 2
    assert test.held == {"airflow/dags/a.py", "airflow/dags/a2.py"}


def test_promotion_releases_files(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    repo.squash_into_main({"airflow/dags/a.py": "a = 2\n"}, "feature a (#200)")
    repo.refresh()
    assert so.sync() == 0
    repo.refresh()

    (test,) = so.discover_tests()

    assert not test.active


# ------------------------------------------------------------------ guards


def test_guard_blocks_iac(repo):
    head = repo.branch("feature/tf", {"iac/x/main.tf": "resource {}\n"})
    repo.refresh()

    verdicts = so.evaluate_staging_prs([pr(1, "feature/tf", head)], [], set())

    assert verdicts[1].state == "failure"
    assert "iac/" in verdicts[1].description


def test_guard_waits_on_held_file_then_passes(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    pr_a = repo.merge_into_staging("feature/a", a)
    b = repo.branch("feature/b", {"airflow/dags/a.py": "a = 3\n"})
    repo.refresh()

    verdict = so.evaluate_staging_prs(
        [pr(2, "feature/b", b)], so.discover_tests(), set()
    )[2]
    assert verdict.state == "pending"
    assert f"#{pr_a}" in verdict.description

    so.rebuild({"cal-itp/feature/a"}, "dropped for the test")
    repo.refresh()
    verdict = so.evaluate_staging_prs(
        [pr(2, "feature/b", b)], so.discover_tests(), set()
    )[2]
    assert verdict.state == "success"


def test_guard_allows_updating_own_test(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    a2 = repo.branch("feature/a", {"airflow/dags/a.py": "a = 4\n"}, base="feature/a")
    repo.refresh()

    verdict = so.evaluate_staging_prs(
        [pr(3, "feature/a", a2)], so.discover_tests(), set()
    )[3]

    assert verdict.state == "success"


def test_guard_reserves_files_for_older_pr(repo):
    b = repo.branch("feature/b", {"airflow/dags/shared.py": "b\n"})
    c = repo.branch("feature/c", {"airflow/dags/shared.py": "c\n"})
    repo.refresh()

    verdicts = so.evaluate_staging_prs(
        [pr(5, "feature/c", c), pr(4, "feature/b", b)], [], set()
    )

    assert verdicts[4].state == "success"
    assert verdicts[5].state == "pending"
    assert "#4" in verdicts[5].description


def test_guard_detects_merged_staging_history(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    repo.branch("feature/b", {"airflow/dags/b.py": "b\n"})
    # What GitHub's "Resolve conflicts" / "Update branch" does
    repo.git(
        "merge",
        "--quiet",
        "--no-ff",
        "origin/staging/official",
        "-m",
        "Merge branch 'staging/official' into feature/b",
    )
    b = repo.git("rev-parse", "HEAD")
    repo.refresh()

    verdict = so.evaluate_staging_prs(
        [pr(6, "feature/b", b)], so.discover_tests(), set()
    )[6]

    assert verdict.state == "failure"
    assert "staging/official" in verdict.description


# -------------------------------------------------------------------- gate


def test_gate_promotion_must_match_staging(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    repo.refresh()
    tests = so.discover_tests()

    ok = so.evaluate_main_pr(pr(10, "feature/a", a), tests, {})
    assert ok.state == "success"

    extra = repo.branch(
        "feature/a", {"airflow/dags/untested.py": "x\n"}, base="feature/a"
    )
    bad = so.evaluate_main_pr(pr(10, "feature/a", extra), tests, {})
    assert bad.state == "failure"
    assert "untested.py" in bad.description


def test_gate_detects_promotion_by_content_on_renamed_branch(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    renamed = repo.branch(
        "feature/a-final",
        {"airflow/dags/a.py": "a = 2\n", "airflow/dags/extra.py": "x\n"},
    )
    repo.refresh()

    verdict = so.evaluate_main_pr(
        pr(11, "feature/a-final", renamed), so.discover_tests(), {}
    )

    assert verdict.state == "failure"
    assert "extra.py" in verdict.description


def test_gate_unrelated_pr_waits_on_held_file(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    pr_a = repo.merge_into_staging("feature/a", a)
    other = repo.branch("hotfix", {"airflow/dags/a.py": "a = 99\n"})
    untouched = repo.branch("docs", {"README.md": "docs\n"})
    repo.refresh()
    tests = so.discover_tests()

    waiting = so.evaluate_main_pr(pr(12, "hotfix", other), tests, {})
    assert waiting.state == "pending"
    assert f"#{pr_a}" in waiting.description
    assert so.evaluate_main_pr(pr(13, "docs", untouched), tests, {}).state == "success"

    overridden = pr(12, "hotfix", other)
    overridden.labels = {so.OVERRIDE_LABEL}
    assert so.evaluate_main_pr(overridden, tests, {}).state == "success"


def test_gate_link_via_promotes_via(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    pr_a = repo.merge_into_staging("feature/a", a)
    repo.refresh()
    tests = so.discover_tests()
    # Linked by body, but changes the held file differently: a failed promotion
    diverged = repo.branch("other-name", {"airflow/dags/a.py": "a = 5\n"})

    verdict = so.evaluate_main_pr(
        pr(14, "other-name", diverged), tests, {pr_a: "Promotes via: #14"}
    )

    assert verdict.state == "failure"


def test_warning_for_dropped_test_commits(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    pr_a = repo.merge_into_staging("feature/a", a)
    stacked = repo.branch("feature/b", {"airflow/dags/b.py": "b\n"}, base="feature/a")
    repo.refresh()
    so.rebuild({"cal-itp/feature/a"}, "dropped")
    repo.refresh()
    records = [
        so.StagingPrRecord(pr_a, a, "cal-itp/feature/a", "2026-10-01T00:00:00Z", "")
    ]

    dropped = so.dropped_tests_in(
        stacked, records, so.discover_tests(), lambda _branch: False
    )

    assert [r.number for r in dropped] == [pr_a]
    text = so.gate_warning(pr(15, "feature/b", stacked), dropped)
    assert "cal-itp/feature/a" in text


# ------------------------------------------------------- rebuild and sync


def test_rebuild_drops_one_test_and_keeps_others(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    b = repo.branch("feature/b", {"airflow/dags/b.py": "b\n"})
    pr_b = repo.merge_into_staging("feature/b", b)
    repo.refresh()

    result = so.rebuild({"cal-itp/feature/a"}, "testing")
    repo.refresh()

    assert [t.branch for t in result.kept] == ["cal-itp/feature/b"]
    assert repo.show("origin/staging/official", "airflow/dags/a.py") == "a = 1"
    assert repo.show("origin/staging/official", "airflow/dags/b.py") == "b"
    (test,) = [t for t in so.discover_tests() if t.active]
    assert test.latest.pr == pr_b  # subject preserved, so it's still recognised
    assert repo.comments and "removed from" in repo.comments[0][1]


def test_sync_merges_main(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    repo.squash_into_main({"README.md": "new readme\n"})
    repo.refresh()

    assert so.sync() == 0
    repo.refresh()

    assert so.is_ancestor(so.MAIN, so.STAGING)
    assert repo.show("origin/staging/official", "airflow/dags/a.py") == "a = 2"
    assert repo.show("origin/staging/official", "README.md") == "new readme"


def test_sync_fast_forwards_without_tests(repo):
    main_sha = repo.squash_into_main({"README.md": "x\n"})
    repo.refresh()

    assert so.sync() == 0
    repo.refresh()

    assert repo.git("rev-parse", "origin/staging/official") == main_sha


def test_sync_conflict_drops_holding_test(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    b = repo.branch("feature/b", {"airflow/dags/b.py": "b\n"})
    repo.merge_into_staging("feature/b", b)
    repo.squash_into_main(
        {"airflow/dags/a.py": "a = 'hotfix'\n"}, "hotfix with override"
    )
    repo.refresh()

    assert so.sync() == 0
    repo.refresh()

    assert so.is_ancestor(so.MAIN, so.STAGING)
    assert repo.show("origin/staging/official", "airflow/dags/a.py") == "a = 'hotfix'"
    assert repo.show("origin/staging/official", "airflow/dags/b.py") == "b"
    active = [t.branch for t in so.discover_tests() if t.active]
    assert active == ["cal-itp/feature/b"]
    assert any("removed from" in body for _, body in repo.comments)


def test_reset_when_clean(repo):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    main_sha = repo.squash_into_main({"airflow/dags/a.py": "a = 2\n"})
    repo.refresh()
    so.sync()
    repo.refresh()

    assert so.reset_if_clean()
    repo.refresh()

    assert repo.git("rev-parse", "origin/staging/official") == main_sha


def test_require_main(repo):
    repo.squash_into_main({"README.md": "x\n"})
    repo.git("checkout", "--quiet", "--detach", "origin/staging/official")
    repo.git("fetch", "--quiet", "origin")

    assert so.cmd_require_main(None) == 1
    repo.git("checkout", "--quiet", "--detach", "origin/main")
    assert so.cmd_require_main(None) == 0


def test_missing_staging_branch_is_treated_as_main(repo):
    repo.git("push", "--quiet", "origin", "--delete", "staging/official")

    assert so.fetch_branches() is False
    assert repo.git("rev-parse", "origin/staging/official") == repo.git(
        "rev-parse", "origin/main"
    )
    assert so.discover_tests() == []


# ------------------------------------------------------------------ expiry


def schedule(repo, deadline, labels=()):
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    pr_a = repo.merge_into_staging("feature/a", a)
    repo.refresh()
    (test,) = so.discover_tests()
    s = so.TestSchedule(
        test=test,
        merged_at=so.parse_time("2026-10-01T00:00:00Z"),
        deadline=so.parse_time(deadline),
        main_pr=None,
        main_pr_state="none",
    )
    meta = {pr_a: {"labels": [{"name": n} for n in labels], "author": {"login": "dev"}}}
    return s, pr_a, meta


@pytest.mark.parametrize(
    "now, expected",
    [
        ("2026-10-10T00:00:00+00:00", None),  # before day 14
        ("2026-10-16T00:00:00+00:00", "nudge"),  # within 7 days
        ("2026-10-21T00:00:00+00:00", "final"),  # within 2 days
        ("2026-10-23T00:00:00+00:00", "expired"),
    ],
)
def test_expiry_notices(repo, monkeypatch, now, expected):
    monkeypatch.setenv("STAGING_NOW", now)
    s, pr_a, meta = schedule(repo, "2026-10-22T00:00:00Z")

    expired = so.process_expiry([s], {}, meta, {pr_a: []})

    if expected == "expired":
        assert expired == [s]
    else:
        assert expired == []
    markers = [body for _, body in repo.comments]
    if expected in ("nudge", "final"):
        assert any(f"staging-monitor:{expected}=" in body for body in markers)
    elif expected is None:
        assert markers == []


def test_notices_are_not_repeated(repo, monkeypatch):
    monkeypatch.setenv("STAGING_NOW", "2026-10-16T00:00:00+00:00")
    s, pr_a, meta = schedule(repo, "2026-10-22T00:00:00Z")
    existing = [{"body": "<!-- staging-monitor:nudge=2026-10-22 -->\nhi"}]

    so.process_expiry([s], {}, meta, {pr_a: existing})

    assert repo.comments == []


def test_keep_label_extends(repo, monkeypatch):
    monkeypatch.setenv("STAGING_NOW", "2026-10-21T00:00:00+00:00")
    removed = []
    monkeypatch.setattr(
        so, "remove_label", lambda n, label: removed.append(label) or True
    )
    s, pr_a, meta = schedule(repo, "2026-10-22T00:00:00Z", labels=[so.KEEP_LABEL])

    expired = so.process_expiry([s], {}, meta, {pr_a: []})

    assert expired == []
    assert s.deadline == so.parse_time("2026-11-05T00:00:00Z")
    assert "extended-until=2026-11-05" in repo.comments[0][1]
    assert so.KEEP_LABEL in removed


def test_keep_label_escalates_when_someone_waits(repo, monkeypatch):
    monkeypatch.setenv("STAGING_NOW", "2026-10-23T00:00:00+00:00")
    monkeypatch.setenv("STAGING_STEWARD", "tihuang02")
    s, pr_a, meta = schedule(repo, "2026-10-22T00:00:00Z", labels=[so.KEEP_LABEL])

    expired = so.process_expiry([s], {s.test.branch: [300]}, meta, {pr_a: []})

    assert expired == [s]  # not extended without the steward
    assert "@tihuang02" in repo.comments[0][1]
    assert "#300" in repo.comments[0][1]


def test_promoted_test_does_not_reclaim_a_file(repo):
    # C keeps staging from ever matching main, so history isn't trimmed.
    c = repo.branch("feature/c", {"airflow/dags/c.py": "c\n"})
    repo.merge_into_staging("feature/c", c)
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n"})
    repo.merge_into_staging("feature/a", a)
    repo.squash_into_main({"airflow/dags/a.py": "a = 2\n"}, "feature a (#200)")
    repo.refresh()
    so.sync()
    b = repo.branch("feature/b", {"airflow/dags/a.py": "a = 3\n"})
    pr_b = repo.merge_into_staging("feature/b", b)
    repo.refresh()

    tests = {t.branch: t for t in so.discover_tests()}

    assert not tests["cal-itp/feature/a"].active
    assert tests["cal-itp/feature/b"].held == {"airflow/dags/a.py"}
    b2 = repo.branch("feature/b", {"airflow/dags/a.py": "a = 4\n"}, base="feature/b")
    verdict = so.evaluate_staging_prs(
        [pr(20, "feature/b", b2)], list(tests.values()), set()
    )[20]
    assert verdict.state == "success"
    assert so.held_map(list(tests.values()))["airflow/dags/a.py"].latest.pr == pr_b


def test_sync_drops_test_when_main_overrides_without_conflict(repo):
    # Held file changed on main in a different region: git would merge cleanly.
    repo.squash_into_main({"airflow/dags/a.py": "a = 1\n\n\n\n\nz = 0\n"})
    a = repo.branch("feature/a", {"airflow/dags/a.py": "a = 2\n\n\n\n\nz = 0\n"})
    repo.merge_into_staging("feature/a", a)
    repo.squash_into_main({"airflow/dags/a.py": "a = 1\n\n\n\n\nz = 'override'\n"})
    repo.refresh()

    assert so.sync() == 0
    repo.refresh()

    assert (
        repo.show("origin/staging/official", "airflow/dags/a.py")
        == "a = 1\n\n\n\n\nz = 'override'"
    )
    assert not any(t.active for t in so.discover_tests())
    assert any("removed from" in body for _, body in repo.comments)
