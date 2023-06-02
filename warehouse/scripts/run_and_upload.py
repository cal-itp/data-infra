#!/usr/bin/env python

import json
import os
import re
import shutil
import subprocess
from pathlib import Path
from typing import List, Optional

import gcsfs  # type: ignore
import pendulum
import sentry_sdk
import typer
from dbt_artifacts import Manifest, RunResults, RunResultStatus

CALITP_BUCKET__DBT_ARTIFACTS = os.getenv("CALITP_BUCKET__DBT_ARTIFACTS")

artifacts = map(
    Path, ["index.html", "catalog.json", "manifest.json", "run_results.json"]
)

sentry_sdk.init()

app = typer.Typer()


class DbtException(Exception):
    pass


class DbtSeedError(Exception):
    pass


class DbtModelError(Exception):
    pass


class DbtTestError(Exception):
    pass


class DbtTestFail(Exception):
    pass


class DbtTestWarn(Exception):
    pass


class DbtMetabaseSyncFailure(Exception):
    pass


def report_failures_to_sentry(
    run_results: RunResults,
    manifest: Manifest,
    verbose: bool = False,
) -> None:
    failures = [
        result
        for result in run_results.results
        if result.status
        in (
            RunResultStatus.error,
            RunResultStatus.fail,
            RunResultStatus.warn,
        )
    ]

    if not failures:
        typer.secho("WARNING: no failures found to report", fg=typer.colors.YELLOW)
        return

    for failure in failures:
        node = manifest.nodes[failure.unique_id]
        fingerprint = [failure.status.value, failure.unique_id]

        # this is awkward; we need to do string comparisons because the artifact schemas use a single-value enum _per artifact type_
        key_tup = (node.resource_type.value, failure.status)
        exc_types = {
            ("seed", RunResultStatus.error): DbtSeedError,
            ("model", RunResultStatus.error): DbtModelError,
            ("test", RunResultStatus.error): DbtTestError,
            ("test", RunResultStatus.fail): DbtTestFail,
            ("test", RunResultStatus.warn): DbtTestWarn,
        }
        try:
            exc_type = exc_types[key_tup]
        except KeyError:
            typer.secho(
                f"WARNING: failed to look up exception type for {key_tup}",
                fg=typer.colors.YELLOW,
            )
            exc_type = DbtException

        if verbose:
            typer.secho(
                f"reporting {exc_type} for {node.unique_id} with fingerprint {fingerprint}",
                fg=typer.colors.YELLOW,
            )
        with sentry_sdk.push_scope() as scope:
            scope.fingerprint = fingerprint
            scope.set_context("dbt_failure", failure.dict())
            scope.set_context("dbt_node", node.dict())
            sentry_sdk.capture_exception(
                error=exc_type(f"{failure.unique_id} - {failure.message}"),
            )


@app.command()
def report_failures(
    run_results_path: str = "./target/run_results.json",
    manifest_path: str = "./target/manifest.json",
    verbose: bool = False,
):
    fs = gcsfs.GCSFileSystem(
        project="cal-itp-data-infra",
        token=os.getenv("BIGQUERY_KEYFILE_LOCATION"),
    )

    openf = fs.open if run_results_path.startswith("gs://") else open
    typer.secho(f"Reading manifest from {manifest_path}", fg=typer.colors.MAGENTA)
    with openf(run_results_path) as f:
        run_results = RunResults(**json.load(f))

    openf = fs.open if manifest_path.startswith("gs://") else open
    typer.secho(f"Reading run results from {run_results_path}", fg=typer.colors.MAGENTA)
    with openf(manifest_path) as f:
        manifest = Manifest(**json.load(f))

    report_failures_to_sentry(run_results, manifest, verbose=verbose)


@app.command()
def run(
    project_dir: Path = Path(os.environ.get("DBT_PROJECT_DIR", os.getcwd())),
    profiles_dir: Path = Path(os.environ.get("DBT_PROFILES_DIR", os.getcwd())),
    target: Optional[str] = os.environ.get("DBT_TARGET"),
    dbt_seed: bool = True,
    dbt_run: bool = True,
    full_refresh: bool = False,
    dbt_test: bool = False,
    dbt_freshness: bool = False,
    dbt_docs: bool = False,
    save_artifacts: bool = False,
    deploy_docs: bool = False,
    sync_metabase: bool = False,
    check_sync_metabase: bool = False,
    select: Optional[str] = None,
    dbt_vars: Optional[str] = None,
    exclude: Optional[str] = None,
) -> None:
    assert (
        dbt_docs or not save_artifacts
    ), "cannot save artifacts without generating them!"
    assert (
        CALITP_BUCKET__DBT_ARTIFACTS or not save_artifacts
    ), "must specify an artifacts bucket if saving artifacts"
    assert dbt_docs or not deploy_docs, "cannot deploy docs without generating them!"

    def get_command(*args) -> List[str]:
        cmd = [
            "dbt",
            *args,
            "--project-dir",
            project_dir,
            "--profiles-dir",
            profiles_dir,
        ]

        if target:
            cmd.extend(
                [
                    "--target",
                    target,
                ]
            )
        typer.secho(f"generated dbt command: {cmd}", fg=typer.colors.MAGENTA)
        return cmd

    results_to_check = []

    if dbt_seed:
        results_to_check.append(subprocess.run(get_command("seed")))

        with open("./target/run_results.json") as f:
            run_results = RunResults(**json.load(f))
        with open("./target/manifest.json") as f:
            manifest = Manifest(**json.load(f))

        report_failures_to_sentry(run_results, manifest)

    if dbt_run:
        args = ["run"]
        if full_refresh:
            args.append("--full-refresh")
        if select:
            args.extend(["--select", *select.split(" ")])
        if dbt_vars:
            args.extend(["--vars", dbt_vars])
        if exclude:
            args.extend(["--exclude", exclude])
        results_to_check.append(subprocess.run(get_command(*args)))

        with open("./target/run_results.json") as f:
            run_results = RunResults(**json.load(f))
        with open("./target/manifest.json") as f:
            manifest = Manifest(**json.load(f))
        report_failures_to_sentry(run_results, manifest)
    else:
        typer.secho("skipping run, only compiling", fg=typer.colors.YELLOW)
        args = ["compile"]
        if full_refresh:
            args.append("--full-refresh")
        subprocess.run(get_command(*args)).check_returncode()

    if dbt_test:
        args = ["test"]
        if exclude:
            args.extend(["--exclude", exclude])
        if select:
            args.extend(["--select", *select.split(" ")])
        if dbt_vars:
            args.extend(["--vars", dbt_vars])
        subprocess.run(get_command(*args))

        with open("./target/run_results.json") as f:
            run_results = RunResults(**json.load(f))
        with open("./target/manifest.json") as f:
            manifest = Manifest(**json.load(f))

        report_failures_to_sentry(run_results, manifest)

    if dbt_freshness:
        results_to_check.append(
            subprocess.run(get_command("source", "snapshot-freshness"))
        )

    if dbt_docs:
        subprocess.run(get_command("docs", "generate")).check_returncode()

        try:
            os.mkdir("target/docs_site/")
        except FileExistsError:
            pass

        fs = gcsfs.GCSFileSystem(
            project="cal-itp-data-infra",
            token=os.getenv("BIGQUERY_KEYFILE_LOCATION"),
        )

        ts = pendulum.now()

        # TODO: we need to save run_results from the run and not the docs generate
        for artifact in artifacts:
            _from = str(project_dir / Path("target") / artifact)

            if save_artifacts:
                # Save the latest ones for easy retrieval downstream
                # but also save using the usual artifact types
                latest_to = f"{CALITP_BUCKET__DBT_ARTIFACTS}/latest/{artifact}"
                # TODO: this should use PartitionedGCSArtifact at some point
                assert CALITP_BUCKET__DBT_ARTIFACTS  # unsure why mypy wants this
                timestamped_to = "/".join(
                    [
                        CALITP_BUCKET__DBT_ARTIFACTS,
                        str(artifact),
                        f"dt={ts.to_date_string()}",
                        f"ts={ts.to_iso8601_string()}",
                        str(artifact),
                    ]
                )
                typer.echo(f"writing {_from} to {latest_to} and {timestamped_to}")
                fs.put(lpath=_from, rpath=latest_to)
                fs.put(lpath=_from, rpath=timestamped_to)
            else:
                typer.echo(f"skipping upload of {artifact}")

            # avoid copying run_results is unnecessary for the docs site
            # so just skip to avoid any potential information leakage
            if "run_results" not in str(artifact):
                shutil.copy(_from, "target/docs_site/")

        if deploy_docs:
            args = [
                "netlify",
                "deploy",
                "--dir=target/docs_site/",
            ]

            if target and target.startswith("prod"):
                args.append("--prod")

            results_to_check.append(subprocess.run(args))

    if sync_metabase:
        if target and (target.startswith("prod") or target.startswith("staging")):
            typer.secho("syncing documentation to metabase", fg=typer.colors.MAGENTA)
            # Use a subprocess here so we can just parse the stdout/stderr
            p = subprocess.run(
                [
                    "dbt-metabase",
                    "models",
                    "--metabase_exclude_sources",
                    "--dbt_manifest_path",
                    "./target/manifest.json",
                    "--dbt_docs_url",
                    "https://dbt-docs.calitp.org",
                    "--metabase_database",
                    (
                        "Data Marts (formerly Warehouse Views)"
                        if target.startswith("prod")
                        else "(Internal) Staging Warehouse Views"
                    ),
                    "--dbt_schema_excludes",
                    "staging",
                    "payments",
                    "--metabase_sync_skip",
                ],
                env={
                    **os.environ,
                    "COLUMNS": "300",  # we have to make this wide enough to avoid splitting log lines
                },
                capture_output=True,
            )

            if check_sync_metabase:
                results_to_check.append(p)

            with open("./target/manifest.json") as f:
                manifest = Manifest(**json.load(f))
            matches = {}
            for line in p.stdout.decode().splitlines():
                print(line)
                for pattern in (
                    r"WARNING\s+Model\s(?P<dbt_schema>\w+)\.(?P<model>\w+)\snot\sfound\sin\s(?P<db_schema>\w+)",
                    r"WARNING\s+Column\s(?P<column>\w+)\snot\sfound\sin\s(?P<db_schema>\w+)\.(?P<model>\w+)",
                ):
                    match = re.search(pattern, line)
                    if match and match.group("model") not in matches:
                        matches[match.group("model")] = (match, line)
            for model, (first_match, line) in matches.items():
                # Just use a single exception type for now, regardless of whether the model is missing entirely
                # or just a column
                exc = DbtMetabaseSyncFailure(first_match.group())
                with sentry_sdk.push_scope() as scope:
                    scope.fingerprint = [type(exc), model]
                    scope.set_context(
                        "log",
                        {
                            "match": str(first_match),
                            "line": line,
                        },
                    )
                    node = next(
                        node
                        for node in manifest.nodes.values()
                        if node.name == model.lower()
                    )
                    scope.set_context(
                        "dbt",
                        {
                            "path": str(node.original_file_path),
                        },
                    )
                    sentry_sdk.capture_exception(exc, scope=scope)
        else:
            typer.secho(
                f"WARNING: running with non-prod target {target} so skipping metabase sync",
                fg=typer.colors.YELLOW,
            )

    for result in results_to_check:
        result.check_returncode()


if __name__ == "__main__":
    app()
