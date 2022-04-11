#!/usr/bin/env python
import os
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
    only_compile: bool = False,
    docs: bool = False,
    upload: bool = False,
    sync_metabase: bool = False,
) -> None:
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

    if only_compile:
        typer.echo("skipping run, only compiling")
        subprocess.run(get_command("compile")).check_returncode()
    else:
        subprocess.run(get_command("run")).check_returncode()

    if docs:
        subprocess.run(get_command("docs", "generate")).check_returncode()

        fs = gcsfs.GCSFileSystem(
            project="cal-itp-data-infra", token=os.getenv("BIGQUERY_KEYFILE_LOCATION")
        )

        for artifact in artifacts:
            if upload:
                _from = str(project_dir / Path("target") / artifact)
                _to = f"gs://{BUCKET}/latest/{artifact}"
                typer.echo(f"writing {_from} to {_to}")
                fs.put(lpath=_from, rpath=_to)
            else:
                typer.echo(f"skipping upload of {artifact}")

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


if __name__ == "__main__":
    typer.run(run)
