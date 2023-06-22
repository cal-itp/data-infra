import tempfile
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional

import git
from invoke import Result, task
from pydantic import BaseModel, validator

KUSTOMIZE_HELM_TEMPLATE = """
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: {namespace}
resources:
- manifest.yaml
"""


class ReleaseDriver(str, Enum):
    helm = "helm"
    kustomize = "kustomize"


class Release(BaseModel):
    name: str
    driver: ReleaseDriver

    # for helm
    namespace: Optional[str]
    helm_name: Optional[str]
    helm_chart: Optional[Path]
    helm_values: List[Path] = []

    # for kustomize
    kustomize_dir: Optional[Path]

    @validator("helm_values", pre=True)
    def split_helm_values(cls, v):
        return v.split(":")


class Channel(BaseModel):
    releases: List[Release]


# TODO: rename this
class Config(BaseModel):
    git_repo: git.Repo
    kdiff_outfile: str
    channels: Dict[str, Channel]

    class Config:
        arbitrary_types_allowed = True

    @validator("git_repo", pre=True)
    def parse_git_repo(cls, v):
        return git.Repo(v, search_parent_directories=True)

    @property
    def git_root(self) -> Path:
        return Path(self.git_repo.working_tree_dir)


@task
def parse_calitp_config(c):
    c.update({"calitp_config": Config(**c.config._config["calitp"])})


@task(parse_calitp_config)
def kdiff(
    c,
    channel,
    app=None,
    outfile=None,
):
    full_diff = ""

    release: Release
    for release in c.calitp_config.channels[channel].releases:
        if release.driver == ReleaseDriver.kustomize and (
            not app or app == release.name
        ):
            kustomize_dir = c.calitp_config.git_root / Path(release.kustomize_dir)
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


@task(parse_calitp_config)
def hdiff(
    c,
    channel,
    app=None,
    outfile=None,
):
    full_diff = ""

    release: Release
    for release in c.calitp_config.channels[channel].releases:
        if release.driver == ReleaseDriver.helm and (not app or app == release.name):
            chart_path = c.calitp_config.git_root / Path(release.helm_chart)
            cmd = f"helm dependency update {chart_path}"
            print(cmd, flush=True)
            c.run(
                cmd,
                warn=True,
            )
            with tempfile.TemporaryDirectory() as tmpdir:
                manifest_path = Path(tmpdir) / Path("manifest.yaml")
                kustomization_path = Path(tmpdir) / Path("kustomization.yaml")
                values_str = " ".join(
                    [
                        f"--values {c.calitp_config.git_root / Path(values_file)}"
                        for values_file in release.helm_values
                    ]
                )
                cmd = f"helm template {release.helm_name} {chart_path} --namespace {release.namespace} {values_str} > {manifest_path}"
                print(cmd, flush=True)
                c.run(
                    cmd,
                    warn=True,
                )
                with open(kustomization_path, "w") as f:
                    f.write(KUSTOMIZE_HELM_TEMPLATE.format(namespace=release.namespace))
                cmd = f"kubectl diff -k {tmpdir}"
                print(cmd, flush=True)
                result: Result = c.run(
                    cmd,
                    warn=True,
                )
            if result.exited != 0:
                full_diff += result.stdout
    c.update({"hdiff": full_diff})
    if outfile:
        msg = f"```{full_diff}```" if full_diff else "No kustomize changes found."
        print(f"writing {len(msg)=} to {outfile}", flush=True)
        with open(outfile, "w") as f:
            f.write(msg)


# TODO: we may want to split up channels into separate files so channel is not an argument but a config file
@task(parse_calitp_config)
def krelease(c, channel, app=None):
    release: Release
    for release in c.calitp_config.channels[channel].releases:
        if release.driver == ReleaseDriver.kustomize and (
            not app or app == release.name
        ):
            kustomize_dir = c.calitp_config.git_root / Path(release.kustomize_dir)
            cmd = f"kubectl apply -k {kustomize_dir}"
            print(cmd, flush=True)
            c.run(cmd)
