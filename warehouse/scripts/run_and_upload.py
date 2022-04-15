#!/usr/bin/env python
import os
import shutil
import subprocess
from pathlib import Path
from typing import List

import gcsfs
import typer

BUCKET = "calitp-dbt-artifacts"

artifacts = map(
    Path, ["index.html", "catalog.json", "manifest.json", "run_results.json"]
)


def run(
    project_dir: Path = os.environ.get("DBT_PROJECT_DIR", os.getcwd()),
    profiles_dir: Path = os.environ.get("DBT_PROFILES_DIR", os.getcwd()),
    target: str = os.environ.get("DBT_TARGET"),
    dbt_run: bool = True,
    dbt_test: bool = True,
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

    if dbt_run:
        subprocess.run(get_command("run")).check_returncode()
    else:
        typer.echo("skipping run, only compiling")
        subprocess.run(get_command("compile")).check_returncode()

    if dbt_test:
        test_result = subprocess.run(get_command("test"))
    else:
        test_result = None

    if dbt_docs:
        subprocess.run(get_command("docs", "generate")).check_returncode()

        os.mkdir("docs/")

        fs = gcsfs.GCSFileSystem(
            project="cal-itp-data-infra", token=os.getenv("BIGQUERY_KEYFILE_LOCATION")
        )

        for artifact in artifacts:
            _from = str(project_dir / Path("target") / artifact)

            if save_artifacts:
                _to = f"gs://{BUCKET}/latest/{artifact}"
                typer.echo(f"writing {_from} to {_to}")
                fs.put(lpath=_from, rpath=_to)
            else:
                typer.echo(f"skipping upload of {artifact}")

            shutil.copy(_from, "docs/")

        if deploy_docs:
            subprocess.run(
                [
                    "netlify",
                    "deploy",
                    "--dir=docs/",
                    # "--alias=dbt-docs",
                ],
            )

    if sync_metabase:
        subprocess.run(
            [
                "dbt-metabase",
                "models",
                "--dbt_manifest_path",
                "./target/manifest.json",
                "--dbt_database",
                "cal-itp-data-infra",
                "--metabase_host",
                "dashboards.calitp.org",
                "--metabase_user",
                os.environ["METABASE_USER"],
                "--metabase_password",
                os.environ["METABASE_PASSWORD"],
                "--metabase_database",
                "Warehouse Views",
            ]
        )

    if test_result:
        test_result.check_returncode()


if __name__ == "__main__":
    typer.run(run)
