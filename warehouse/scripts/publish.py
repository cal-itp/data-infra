"""
Publishes various dbt models to various sources.
"""
import json
import os
import tempfile

import gcsfs
import humanize
import pandas as pd
import requests
import typer
from sqlalchemy import create_engine

from scripts.dbt_artifacts import CkanConfig, DbtResourceType, Manifest, Node

API_KEY = os.environ.get("CALITP_CKAN_GTFS_SCHEDULE_KEY")

app = typer.Typer()


# Taken from the calitp repo which we can't install because of deps issue
def get_engine(project, max_bytes=None):
    max_bytes = 5_000_000_000 if max_bytes is None else max_bytes

    # Note that we should be able to add location as a uri parameter, but
    # it is not being picked up, so passing as a separate argument for now.
    return create_engine(
        f"bigquery://{project}/?maximum_bytes_billed={max_bytes}",
        location="us-west2",
        credentials_path=os.environ.get("BIGQUERY_KEYFILE_LOCATION"),
    )


@app.command()
def publish_to_ckan(
    project: str = "cal-itp-data-infra",
    bucket: str = "gs://calitp-publish",
    dry_run: bool = False,
) -> None:
    with open("./target/manifest.json") as f:
        _ = Manifest(**json.load(f))

    engine = get_engine(project)
    for config in CkanConfig._instances:
        with tempfile.TemporaryDirectory() as tmpdir:
            for model_name, ckan_id in config.ids.items():
                table = Node._instances[(DbtResourceType.model, model_name)]

                fpath = os.path.join(tmpdir, f"{model_name}.csv")
                df = pd.read_gbq(
                    str(table.select(engine)),
                    project_id=project,
                    progress_bar_type="tqdm",
                )
                df.to_csv(fpath, index=False)
                typer.secho(
                    f"selected {len(df)} rows ({humanize.naturalsize(os.stat(fpath).st_size)}) from {model_name}"
                )

                hive_path = config.hive_path(model_name, bucket)

                if dry_run:
                    typer.secho(
                        f"would be writing {model_name} to {hive_path} and {config.url} {ckan_id}",
                        fg=typer.colors.MAGENTA,
                    )
                else:
                    fs = gcsfs.GCSFileSystem(project=project)
                    fs.put(fpath, hive_path)

                    with open(fpath, "rb") as fp:
                        requests.post(
                            config.url,
                            data={"id": ckan_id},
                            headers={"Authorization": API_KEY},
                            files={"upload": fp},
                        ).raise_for_status()


if __name__ == "__main__":
    app()
