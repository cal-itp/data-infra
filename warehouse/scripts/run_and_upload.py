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
    project_dir: Path = os.environ.get('DBT_PROJECT_DIR', os.getcwd()),
    profiles_dir: Path = os.environ.get('DBT_PROFILES_DIR', os.getcwd()),
    target: str = os.environ.get('DBT_TARGET'),
    docs: bool = False,
    upload: bool = False,
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
            cmd.extend([
                "--target",
                target,
            ])
        return cmd

    subprocess.run(get_command("run"))

    if docs:
        subprocess.run(get_command("docs", "generate"))

        fs = gcsfs.GCSFileSystem(project="cal-itp-data-infra")

        for artifact in artifacts:
            if upload:
                _from = str(project_dir / Path("target") / artifact)
                _to = f"gs://{BUCKET}/latest/{artifact}"
                typer.echo(f"writing {_from} to {_to}")
                fs.put(lpath=_from, rpath=_to)
            else:
                typer.echo(f"skipping upload of {artifact}")


if __name__ == "__main__":
    typer.run(run)
