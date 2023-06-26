import tempfile
from enum import Enum
from pathlib import Path
from typing import List, Optional

import git
import yaml
from google.cloud import secretmanager
from invoke import Exit, Result, task
from pydantic import BaseModel, validator

KUSTOMIZE_HELM_TEMPLATE = """
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: {namespace}
resources:
- manifest.yaml
"""


GENERIC_HELP = {
    "driver": "The k8s driver (kustomize or helm)",
    "app": "The specific app/release (e.g. metabase or archiver)",
}


class ReleaseDriver(str, Enum):
    helm = "helm"
    kustomize = "kustomize"


class Release(BaseModel):
    name: str
    driver: ReleaseDriver

    # we could consider labeling secrets and pulling all secrets by label
    # but that moves some logic into Secret Manager itself
    secrets: List[str] = []

    # for helm
    namespace: Optional[str]
    helm_name: Optional[str]
    helm_chart: Optional[Path]
    helm_values: List[Path] = []

    # for kustomize
    kustomize_dir: Optional[Path]


class CalitpConfig(BaseModel):
    git_repo: git.Repo
    channel: str  # this is a bit weird, but I want to be able to log this value
    releases: List[Release]

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
    c.update({"calitp_config": CalitpConfig(**c.config._config["calitp"])})


def get_releases(
    c,
    driver: Optional[ReleaseDriver] = None,
    app=None,
) -> List[Release]:
    ret = []
    for release in c.calitp_config.releases:
        if (not driver or release.driver == driver) and (
            not app or app == release.name
        ):
            ret.append(release)
    return ret


# TODO: kubectl diff now supports masking secrets, so we should be able to render secret diffs in PRs
#  see https://github.com/kubernetes/kubernetes/pull/96084
@task(
    parse_calitp_config,
    help={
        "app": GENERIC_HELP["app"],
        "secret": "Optionally, specify a single secret to deploy",
    },
)
def secrets(
    c,
    app=None,
    secret=None,
    hide=True,
):
    """
    Deploy secret(s) by channel, and optionally app or secret name.
    """
    client = secretmanager.SecretManagerServiceClient()
    found_secret = False
    for release in get_releases(c, app=app):
        for release_secret in release.secrets:
            if not secret or secret == release_secret:
                with tempfile.TemporaryDirectory() as tmpdir:
                    secret_path = Path(tmpdir) / Path(f"{release_secret}.yml")
                    # this ID maps to cal-itp-data-infra; there's probably a better way to do this
                    # TODO: we could probably just use gcloud CLI for this
                    name = f"projects/1005246706141/secrets/{release_secret}/versions/latest"
                    secret_contents = client.access_secret_version(
                        request={"name": name}
                    ).payload.data.decode("UTF-8")

                    if release.namespace:
                        ns_str = f"--namespace {release.namespace}"
                    else:
                        ns_str = ""
                        assert (
                            "namespace" in yaml.safe_load(secret_contents)["metadata"]
                        )

                    with open(secret_path, "w") as f:
                        f.write(secret_contents)
                    print(f"Applying {release_secret}...", flush=True)
                    result = c.run(
                        f"kubectl apply {ns_str} -f {secret_path}", hide=hide, warn=True
                    )
                    if result.exited:
                        print(
                            f"FAILURE: Failed to apply secret {release_secret}.",
                            flush=True,
                        )
                        raise Exit
                    print(f"Successfully applied {release_secret}.", flush=True)
                found_secret = True

    if not found_secret:
        print("WARNING: Failed to deploy any secrets.", flush=True)


@task(
    parse_calitp_config,
    help={
        **GENERIC_HELP,
        "outfile": "File in which to save the combined kubectl diff output",
    },
)
def diff(
    c,
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

    for release in get_releases(c, driver=actual_driver, app=app):
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
                # TODO: consider looking into https://github.com/databus23/helm-diff
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
        else f"No {driver if driver else 'manifest'} changes found for {c.calitp_config.channel}.\n"
    )
    if outfile:
        print(f"writing {len(msg)=} to {outfile}", flush=True)
        with open(outfile, "w") as f:
            f.write(msg)
    else:
        print(msg, flush=True)


@task(parse_calitp_config, help=GENERIC_HELP)
def release(
    c,
    driver=None,
    app=None,
):
    """
    Releases (i.e. deploys) apps into a specific channel.
    """
    assert c.calitp_config.git_root is not None
    actual_driver = ReleaseDriver[driver] if driver else None

    for release in get_releases(c, driver=actual_driver, app=app):
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
