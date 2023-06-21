import os
from enum import Enum
from pathlib import Path
from typing import Any, Generator, List, Optional

import git
from invoke import Result, task
from pydantic import BaseSettings


class ReleaseDriver(str, Enum):
    helm = "helm"
    kustomize = "kustomize"


class Release(BaseSettings):
    name: str
    release_driver: ReleaseDriver

    # for helm
    release_namespace: Optional[str]
    release_helm_name: Optional[str]
    release_helm_chart: Optional[Path]
    release_helm_values: Optional[List[Path]]

    # for kustomize
    release_kustomize_dir: Optional[Path]

    class Config:
        @classmethod
        def parse_env_var(cls, field_name: str, raw_val: str) -> Any:
            if field_name == "release_helm_values":
                return raw_val.split(":")
            return cls.json_loads(raw_val)


def get_releases(
    channel: str,
    releases_dir="./vars/releases",
    driver: Optional[ReleaseDriver] = None,
) -> Generator[Release, None, None]:
    for release in Path(releases_dir).glob(f"{channel}-*"):
        r = Release(
            name=str(release),
            _env_file=release,
            _env_file_encoding="utf-8",
        )
        if not driver or r.release_driver == driver:
            yield r


@task
def kdiff(
    c,
    channel,
    app=None,
    outfile=os.getenv("GITHUB_OUTPUT"),
):
    repo = git.Repo(".", search_parent_directories=True)

    full_diff = ""

    for release in get_releases(channel, driver=ReleaseDriver.kustomize):
        if not app or app == release.name:
            kustomize_dir = Path(repo.working_tree_dir) / Path(
                release.release_kustomize_dir
            )
            result: Result = c.run(
                f"kubectl diff -k {kustomize_dir}",
                echo=True,
                warn=True,
            )
            if result.exited != 0:
                full_diff += result.stdout

    if full_diff and outfile:
        print(f"writing to {outfile}")
        with open(outfile, "a") as f:
            f.write(f"DIFF={full_diff}")
    print(flush=True)
