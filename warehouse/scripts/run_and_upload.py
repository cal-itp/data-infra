#!/usr/bin/env python
import os
import subprocess
from pathlib import Path
from typing import List

import gcsfs
import typer

BUCKET = "calitp-dbt-artifacts"

artifacts = []


def run(
    project_dir: Path = os.getcwd(),
    profiles_dir: Path = os.getcwd(),
    upload: bool = False,
) -> None:
    def get_command(*args) -> List[str]:
        return [
            "dbt",
            *args,
            "--project-dir",
            project_dir,
        ]

    subprocess.run(get_command("run"))

    if upload:
        fs = gcsfs.GCSFileSystem(project="cal-itp-data-infra")
        fs.put()
    else:
        print("skipping upload")


if __name__ == "__main__":
    typer.run(run)
