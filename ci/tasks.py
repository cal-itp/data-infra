import os
from pathlib import Path

import git
from decouple import Config, RepositoryEnv
from invoke import Result, task


@task
def fail(c):
    c.run("this does not exist")


@task
def kdiff(
    c,
    channel,
    app=None,
    releases_dir="./vars/releases",
    outfile=os.getenv("GITHUB_OUTPUT"),
):
    repo = git.Repo(".", search_parent_directories=True)

    full_diff = ""

    for release in Path(releases_dir).glob(f"{channel}-*"):
        env = Config(RepositoryEnv(release))
        if env.get("RELEASE_DRIVER") == "kustomize" and (
            not app or app == release.name
        ):
            kustomize_dir = Path(repo.working_tree_dir) / Path(
                env.get("RELEASE_KUSTOMIZE_DIR")
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
