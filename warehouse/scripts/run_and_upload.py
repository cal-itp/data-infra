#!/usr/bin/env python

import os
import subprocess
from pathlib import Path
from typing import List, Optional

import typer

CALITP_BUCKET__DBT_ARTIFACTS = os.environ.get("CALITP_BUCKET__DBT_ARTIFACTS")

artifacts = map(
    Path,
    [
        "index.html",
        "catalog.json",
        "manifest.json",
        "run_results.json",
        "partial_parse.msgpack",
    ],
)

app = typer.Typer()


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
    save_artifacts: bool = False,
    select: Optional[str] = None,
    dbt_vars: Optional[str] = None,
    exclude: Optional[str] = None,
) -> None:
    assert (
        CALITP_BUCKET__DBT_ARTIFACTS or not save_artifacts
    ), "must specify an artifacts bucket if saving artifacts"

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

    if dbt_freshness:
        results_to_check.append(
            subprocess.run(get_command("source", "snapshot-freshness"))
        )

    for result in results_to_check:
        result.check_returncode()


if __name__ == "__main__":
    app()
