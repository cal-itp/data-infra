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
    project_dir: Path = os.getcwd(),
    profiles_dir: Path = os.getcwd(),
    docs: bool = False,
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

    if docs:
        subprocess.run(get_command("docs", "generate"))

        fs = gcsfs.GCSFileSystem(project="cal-itp-data-infra")

        for artifact in artifacts:
            if upload:
                _from = str(project_dir / Path("target") / artifact)
                _to = str(Path(f"gs://{BUCKET}") / Path("latest"))
                fs.put(lpath=_from, rpath=_to)
            else:
                print(f"skipping upload of {artifact}")


if __name__ == "__main__":
    typer.run(run)
