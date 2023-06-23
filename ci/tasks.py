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
    """
    Parses the top-level calitp configuration key via Pydantic
    """
    c.update({"calitp_config": Config(**c.config._config["calitp"])})


def get_releases(c, channel, driver: ReleaseDriver, app=None) -> List[Release]:
    ret = []
    for release in c.calitp_config.channels[channel].releases:
        if (not driver or release.driver == driver) and (
            not app or app == release.name
        ):
            ret.append(release)
    return ret


@task(
    parse_calitp_config,
    help={
        "channel": "The release channel/environment, e.g. test or prod",
        "driver": "The k8s driver (kustomize or helm)",
    },
)
def diff(
    c,
    channel: str,
    driver=None,
    app=None,
    outfile=None,
):
    """
    Applies kubectl diff to manifests for a given channel.
    """
    actual_driver = ReleaseDriver[driver] if driver else None
    full_diff = ""

    release: Release
    for release in get_releases(c, channel, driver=actual_driver, app=app):
        if release.driver == ReleaseDriver.kustomize:
            kustomize_dir = c.calitp_config.git_root / Path(release.kustomize_dir)
            result: Result = c.run(f"kubectl diff -k {kustomize_dir}", warn=True)
        elif release.driver == ReleaseDriver.helm:
            chart_path = c.calitp_config.git_root / Path(release.helm_chart)
            c.run(f"helm dependency update {chart_path}")

            with tempfile.TemporaryDirectory() as tmpdir:
                manifest_path = Path(tmpdir) / Path("manifest.yaml")
                kustomization_path = Path(tmpdir) / Path("kustomization.yaml")
                values_str = " ".join(
                    [
                        f"--values {c.calitp_config.git_root / Path(values_file)}"
                        for values_file in release.helm_values
                    ]
                )
                c.run(
                    f"helm template {release.helm_name} {chart_path} --namespace {release.namespace} {values_str} > {manifest_path}"
                )
                with open(kustomization_path, "w") as f:
                    f.write(KUSTOMIZE_HELM_TEMPLATE.format(namespace=release.namespace))
                result: Result = c.run(f"kubectl diff -k {tmpdir}", warn=True)
        else:
            print(f"Encountered unknown driver: {release.driver}", flush=True)
            raise RuntimeError

        if result.exited != 0:
            full_diff += result.stdout

    msg = (
        f"```{full_diff}```"
        if full_diff
        else f"No {driver if driver else 'manifest'} changes found for {channel}.\n"
    )
    if outfile:
        print(f"writing {len(msg)=} to {outfile}", flush=True)
        with open(outfile, "w") as f:
            f.write(msg)
    else:
        print(msg, flush=True)


# TODO: we may want to split up channels into separate files so channel is not an argument but a config file
@task(parse_calitp_config)
def release(
    c,
    channel: str,
    driver=None,
    app=None,
):
    release: Release
    actual_driver = ReleaseDriver[driver] if driver else None
    for release in get_releases(c, channel, driver=actual_driver, app=app):
        if release.driver == ReleaseDriver.kustomize:
            kustomize_dir = c.calitp_config.git_root / Path(release.kustomize_dir)
            c.run(f"kubectl apply -k {kustomize_dir}")
        elif release.driver == ReleaseDriver.helm:
            chart_path = c.calitp_config.git_root / Path(release.helm_chart)
            c.run(f"helm dependency update {chart_path}", warn=True)
            values_str = " ".join(
                [
                    f"--values {c.calitp_config.git_root / Path(values_file)}"
                    for values_file in release.helm_values
                ]
            )
            result: Result = c.run(f"kubectl get ns {release.namespace}")
            verb = "upgrade"

            if result.exited != 0:
                # namespace does not exist yet
                c.run(f"kubectl create ns {release.namespace}")
                verb = "install"

            c.run(
                f"helm {verb} {release.helm_name} {chart_path} --namespace {release.namespace} {values_str}"
            )
        else:
            print(f"Encountered unknown driver: {release.driver}", flush=True)
            raise RuntimeError
