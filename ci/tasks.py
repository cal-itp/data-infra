import tempfile
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional

import git
from google.cloud import secretmanager
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

    # we could consider labeling secrets and pulling all secrets by label
    # but that moves some logic into Secret Manager itself
    secrets: Optional[List[str]]

    # for helm
    namespace: Optional[str]
    helm_name: Optional[str]
    helm_chart: Optional[Path]
    helm_values: List[Path] = []

    # for kustomize
    kustomize_dir: Optional[Path]


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
    def git_root(self) -> Optional[Path]:
        if not self.git_repo.working_tree_dir:
            return None
        return Path(self.git_repo.working_tree_dir)


@task
def parse_calitp_config(c):
    """
    Parses the top-level calitp configuration key via Pydantic
    """
    c.update({"calitp_config": Config(**c.config._config["calitp"])})


def get_releases(
    c, channel, driver: Optional[ReleaseDriver] = None, app=None
) -> List[Release]:
    ret = []
    for release in c.calitp_config.channels[channel].releases:
        if (not driver or release.driver == driver) and (
            not app or app == release.name
        ):
            ret.append(release)
    return ret


GENERIC_HELP = {
    "channel": "The release channel/environment, e.g. test or prod",
    "driver": "The k8s driver (kustomize or helm)",
    "app": "The specific app/release (e.g. metabase or archiver)",
}


@task(
    parse_calitp_config,
    help={
        "channel": GENERIC_HELP["channel"],
        "app": GENERIC_HELP["app"],
        "secret": "Optionally, specify a single secret to deploy",
    },
)
def deploy_secret(
    c,
    channel: str,
    app=None,
    secret=None,
):
    """
    Deploy secret(s) by channel, and optionally app or secret name.
    """
    client = secretmanager.SecretManagerServiceClient()
    found_secret = False
    for release in get_releases(c, channel, app=app):
        for release_secret in release.secrets:
            if not secret or secret == release_secret:
                with tempfile.TemporaryDirectory() as tmpdir:
                    secret_path = Path(tmpdir) / Path(f"{release_secret}.yml")
                    # this ID maps to cal-itp-data-infra; there's probably a better way to do this
                    name = f"projects/1005246706141/secrets/{release_secret}/versions/latest"
                    secret_contents = client.access_secret_version(
                        request={"name": name}
                    ).payload.data.decode("UTF-8")
                    with open(secret_path, "w") as f:
                        f.write(secret_contents)
                    c.run(
                        f"kubectl apply --namespace {release.namespace} -f {secret_path}"
                    )
                found_secret = True

    if not found_secret:
        print("Failed to deploy any secrets.")


@task(
    parse_calitp_config,
    help={
        **GENERIC_HELP,
        "outfile": "File in which to save the combined kubectl diff output",
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
    assert c.calitp_config.git_root is not None
    actual_driver = ReleaseDriver[driver] if driver else None
    full_diff = ""
    result: Result

    for release in get_releases(c, channel, driver=actual_driver, app=app):
        if release.driver == ReleaseDriver.kustomize:
            assert release.kustomize_dir is not None
            kustomize_dir = c.calitp_config.git_root / Path(release.kustomize_dir)
            result = c.run(f"kubectl diff -k {kustomize_dir}", warn=True)
        elif release.driver == ReleaseDriver.helm:
            assert release.helm_chart is not None
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
                result = c.run(f"kubectl diff -k {tmpdir}", warn=True)
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
@task(parse_calitp_config, help=GENERIC_HELP)
def release(
    c,
    channel: str,
    driver=None,
    app=None,
):
    """
    Releases (i.e. deploys) apps into a specific channel.
    """
    assert c.calitp_config.git_root is not None
    actual_driver = ReleaseDriver[driver] if driver else None

    for release in get_releases(c, channel, driver=actual_driver, app=app):
        if release.driver == ReleaseDriver.kustomize:
            assert release.kustomize_dir is not None
            kustomize_dir = c.calitp_config.git_root / Path(release.kustomize_dir)
            c.run(f"kubectl apply -k {kustomize_dir}")
        elif release.driver == ReleaseDriver.helm:
            assert release.helm_chart is not None
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
