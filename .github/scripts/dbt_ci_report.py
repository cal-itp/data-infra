#!/usr/bin/env python3
"""Build the dbt CI report comment for a pull request.

Run inside the warehouse environment (`uv run python ...`) after:
1. `dbt compile --defer --favor-state --select state:modified+`, whose
   manifest.json and run_results.json are in --compile-dir; and
2. `dbt build --empty ...`, whose run_results.json is --build-results.

For each compiled model, a BigQuery dry run estimates the bytes a full
refresh would scan. Refs to unchanged models resolve to the staging tables,
so estimates reflect staging data volumes, not production. Models whose
upstream changed in this PR may not dry-run (new parents don't exist yet).
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

MARKER = "<!-- dbt-ci-report -->"


def human_bytes(n: int) -> str:
    size = float(n)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if size < 1024 or unit == "TB":
            return f"{size:,.1f} {unit}" if unit != "B" else f"{int(size)} B"
        size /= 1024
    return f"{n} B"


def dry_run(client, sql: str) -> tuple[int | None, str]:
    from google.cloud import bigquery  # pyright: ignore[reportAttributeAccessIssue]

    try:
        job = client.query(
            sql, job_config=bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
        )
        return job.total_bytes_processed, ""
    except Exception as error:  # noqa: BLE001 - reported, not raised
        message = str(getattr(error, "message", error)).splitlines()[0]
        return None, message[:160]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compile-dir", type=Path, required=True)
    parser.add_argument("--build-results", type=Path)
    parser.add_argument("--build-outcome", default="")
    parser.add_argument(
        "--modified",
        type=Path,
        required=True,
        help="Directly modified model names, one per line",
    )
    parser.add_argument("--project", required=True, help="GCP project for dry-run jobs")
    parser.add_argument("--skip-dry-run", action="store_true")
    args = parser.parse_args()

    if not (args.compile_dir / "manifest.json").exists():
        print(
            f"{MARKER}\n## dbt CI checks\n\n❌ The checks didn't get far enough to report; see the workflow logs."
        )
        return 0
    manifest = json.loads((args.compile_dir / "manifest.json").read_text())
    compiled = json.loads((args.compile_dir / "run_results.json").read_text())
    modified = {
        line.strip() for line in args.modified.read_text().splitlines() if line.strip()
    }

    client = None
    if not args.skip_dry_run:
        from google.cloud import bigquery  # pyright: ignore[reportAttributeAccessIssue]

        client = bigquery.Client(project=args.project)

    rows = []
    total = 0
    for result in compiled.get("results", []):
        node = manifest["nodes"].get(result["unique_id"])
        if not node or node.get("resource_type") != "model":
            continue
        config = node.get("config", {})
        materialized = config.get("materialized", "")
        if (
            materialized == "incremental"
            and config.get("incremental_strategy") == "microbatch"
        ):
            materialized = "microbatch"
        name = node["name"]
        estimate = ""
        if materialized in ("ephemeral", "view"):
            estimate = (
                "— (not built from data)" if materialized == "ephemeral" else "— (view)"
            )
        elif client is not None and node.get("compiled_code"):
            scanned, error = dry_run(client, node["compiled_code"])
            if scanned is None:
                estimate = f"n/a: {error}"
            else:
                total += scanned
                estimate = human_bytes(scanned)
        rows.append((name in modified, name, materialized, estimate))

    rows.sort(key=lambda r: (not r[0], r[1]))
    changed = [r for r in rows if r[0]]
    downstream = [r for r in rows if not r[0]]

    out = [MARKER, "## dbt CI checks", ""]
    if args.build_outcome:
        outcome = {
            "success": "✅ passed",
            "failure": "❌ failed",
            "skipped": "skipped",
        }.get(args.build_outcome, args.build_outcome)
        out.append(
            f"**Empty build** (`dbt build --empty` of changed models and downstream): {outcome}"
        )
        if args.build_results and args.build_results.exists():
            failures = [
                r
                for r in json.loads(args.build_results.read_text()).get("results", [])
                if r.get("status") in ("error", "fail")
            ]
            for r in failures[:20]:
                message = (
                    (r.get("message") or "").splitlines()[0][:200]
                    if r.get("message")
                    else ""
                )
                out.append(f"- `{r['unique_id']}`: {r['status']} {message}")
            if len(failures) > 20:
                out.append(f"- …and {len(failures) - 20} more")
        out.append(
            "_Advisory for now: this checks SQL and schemas on empty tables, so data tests pass trivially. "
            "Unchanged upstream models come from the staging datasets; a missing staging table can cause a false failure._"
        )
        out.append("")

    out.append(
        f"**Changed models:** {len(changed)} · **Downstream models:** {len(downstream)}"
    )
    if total:
        out.append(
            f"**Estimated scan for a full refresh: {human_bytes(total)}** "
            "(BigQuery dry run against **staging** data; production volumes can be much larger. "
            "Merging to `main` full-refreshes changed models and runs downstream ones in production.)"
        )
    out.append("")
    if rows:
        out += [
            "<details><summary>Models</summary>",
            "",
            "| model | changed | materialization | est. scan (full refresh, staging) |",
            "|---|---|---|---|",
        ]
        for is_changed, name, materialized, estimate in rows:
            out.append(
                f"| `{name}` | {'yes' if is_changed else 'downstream'} | {materialized} | {estimate} |"
            )
        out += ["", "</details>"]
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
