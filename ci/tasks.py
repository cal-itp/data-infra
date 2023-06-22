from enum import Enum
from pathlib import Path
from typing import List, Optional

import git
from invoke import Result, task
from pydantic import BaseModel, validator

KUSTOMIZE_HELM_TEMPLATE = """
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: {release_namespace}
resources:
- manifest.yaml
"""


class ReleaseDriver(str, Enum):
    helm = "helm"
    kustomize = "kustomize"


class Release(BaseModel):
    name: str
    release_driver: ReleaseDriver

    # for helm
    release_namespace: Optional[str]
    release_helm_name: Optional[str]
    release_helm_chart: Optional[Path]
    release_helm_values: Optional[List[Path]]

    # for kustomize
    release_kustomize_dir: Optional[Path]

    @validator("release_helm_values", pre=True)
    def split_release_helm_values(cls, v):
        return v.split(":")


@task
def load_release(c):
    c.update(
        {
            "releases": [
                Release(**release) for release in c.config._config["calitp"]["releases"]
            ]
        }
    )


@task(load_release)
def kdiff(
    c,
    app=None,
    outfile=None,
):
    repo = git.Repo(c.config.calitp.git_repo_path, search_parent_directories=True)

    full_diff = ""

    release: Release
    for release in c.releases:
        if release.release_driver == ReleaseDriver.kustomize and (
            not app or app == release.name
        ):
            kustomize_dir = Path(repo.working_tree_dir) / Path(
                release.release_kustomize_dir
            )
            cmd = f"kubectl diff -k {kustomize_dir}"
            print(cmd, flush=True)
            result: Result = c.run(
                cmd,
                warn=True,
            )
            if result.exited != 0:
                full_diff += result.stdout
    c.update({"kdiff": full_diff})
    if outfile:
        msg = f"```{full_diff}```" if full_diff else "No kustomize changes found."
        print(f"writing {len(msg)=} to {outfile}", flush=True)
        with open(outfile, "w") as f:
            f.write(msg)


@task(kdiff)
def krelease(c, app=None):
    try:
        c.kdiff

        repo = git.Repo(c.config.calitp.git_repo_path, search_parent_directories=True)
        release: Release
        for release in c.releases:
            if release.release_driver == ReleaseDriver.kustomize and (
                not app or app == release.name
            ):
                kustomize_dir = Path(repo.working_tree_dir) / Path(
                    release.release_kustomize_dir
                )
                cmd = f"kubectl apply -k {kustomize_dir}"
                print(cmd, flush=True)
                c.run(cmd)
    except AttributeError:
        pass
