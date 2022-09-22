#!/usr/bin/env python
import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import List, Dict, Any

import gcsfs
import pendulum
import sentry_sdk
import typer

from dbt_artifacts import (
    RunResults,
    TestStatus,
    Manifest,
    RunResult,
    RunStatus,
)

CALITP_BUCKET__DBT_ARTIFACTS = os.environ["CALITP_BUCKET__DBT_ARTIFACTS"]

artifacts = map(
    Path, ["index.html", "catalog.json", "manifest.json", "run_results.json"]
)

sentry_sdk.init(environment=os.environ["AIRFLOW_ENV"])

app = typer.Typer()


class DbtTestFailure(Exception):
    pass


def get_failure_context(failure: RunResult, manifest: Manifest) -> Dict[str, Any]:
    context = {
        "unique_id": failure.unique_id,
    }
    if failure.unique_id.startswith("test"):
        node = manifest.nodes[failure.unique_id]
        if node.depends_on:
            context["models"] = node.depends_on.nodes
    return context


def report_failures_to_sentry(
    run_results: RunResults, manifest: Manifest = None
) -> None:
    failures = [
        result
        for result in run_results.results
        if result.status
        in (
            RunStatus.error,
            RunStatus.fail,
            TestStatus.fail,
            TestStatus.error,
            TestStatus.warn,
        )
    ]
    for failure in failures:
        with sentry_sdk.push_scope() as scope:
            scope.fingerprint = [failure.unique_id, failure.message]
            scope.set_context("dbt", get_failure_context(failure, manifest))
            sentry_sdk.capture_exception(
                error=DbtTestFailure(f"{failure.unique_id} - {failure.message}"),
            )


@app.command()
def report_failures(
    run_results_path: Path = "./target/run_results.json",
    manifest_path: Path = "./target/manifest.json",
):
    with open(run_results_path) as f:
        run_results = RunResults(**json.load(f))
    with open(manifest_path) as f:
        manifest = Manifest(**json.load(f))
    report_failures_to_sentry(run_results, manifest)


@app.command()
def run(
    project_dir: Path = os.environ.get("DBT_PROJECT_DIR", os.getcwd()),
    profiles_dir: Path = os.environ.get("DBT_PROFILES_DIR", os.getcwd()),
    target: str = os.environ.get("DBT_TARGET"),
    dbt_run: bool = True,
    full_refresh: bool = False,
    dbt_test: bool = False,
    dbt_freshness: bool = False,
    dbt_docs: bool = False,
    save_artifacts: bool = False,
    deploy_docs: bool = False,
    sync_metabase: bool = False,
) -> None:
    assert (
        dbt_docs or not save_artifacts
    ), "cannot save artifacts without generating them!"
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
        return cmd

    subprocess.run(get_command("compile")).check_returncode()

    results_to_check = []

    if dbt_run:
        args = ["run"]
        if full_refresh:
            args.append("--full-refresh")
        results_to_check.append(subprocess.run(get_command(*args)))

        with open("./target/run_results.json") as f:
            run_results = RunResults(**json.load(f))
        with open("./target/manifest.json") as f:
            manifest = Manifest(**json.load(f))
        report_failures_to_sentry(run_results, manifest)
    else:
        typer.echo("skipping run")

    if dbt_test:
        subprocess.run(get_command("test"))

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

        os.mkdir("docs/")

        fs = gcsfs.GCSFileSystem(
            project="cal-itp-data-infra",
            token=os.getenv("BIGQUERY_KEYFILE_LOCATION"),
        )

        ts = pendulum.now()

        for artifact in artifacts:
            _from = str(project_dir / Path("target") / artifact)

            if save_artifacts:
                # Save the latest ones for easy retrieval downstream
                # but also save using the usual artifact types
                latest_to = f"{CALITP_BUCKET__DBT_ARTIFACTS}/latest/{artifact}"
                # TODO: this should use PartitionedGCSArtifact at some point
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
                shutil.copy(_from, "docs/")

        if deploy_docs:
            args = [
                "netlify",
                "deploy",
                "--dir=docs/",
            ]

            if target.startswith("prod"):
                args.append("--prod")

            results_to_check.append(subprocess.run(args))

    if sync_metabase:
        for schema, database in [
            ("views", "Data Marts (formerly Warehouse Views)"),
            ("gtfs_schedule", "GTFS Schedule Feeds Latest"),
            ("mart_transit_database", "Data Marts (formerly Warehouse Views)"),
            ("mart_gtfs_guidelines", "Data Marts (formerly Warehouse Views)"),
        ]:
            args = [
                "dbt-metabase",
                "models",
                "--dbt_manifest_path",
                "./target/manifest.json",
                "--dbt_database",
                "cal-itp-data-infra",
                "--dbt_schema",
                schema,
                "--metabase_host",
                "dashboards.calitp.org",
                "--metabase_user",
                os.environ["METABASE_USER"],
                "--metabase_password",
                os.environ["METABASE_PASSWORD"],
                "--metabase_database",
                database,
            ]
            results_to_check.append(subprocess.run(args))

    for result in results_to_check:
        result.check_returncode()


if __name__ == "__main__":
    app()
