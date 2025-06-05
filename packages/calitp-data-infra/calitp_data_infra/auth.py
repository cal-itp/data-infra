import os
from typing import Mapping

from google.cloud import secretmanager  # type: ignore


def get_gcp_project_id() -> str:
    """
    Get the GCP project ID from the environment variable. Try the following
    environment variables in order:
    1. GOOGLE_CLOUD_PROJECT
    2. GCP_PROJECT
    3. PROJECT_ID

    Cloud Composer should set at least one of these environment variables. See
    https://cloud.google.com/composer/docs/composer-3/set-environment-variables
    """
    try:
        return os.environ["GOOGLE_CLOUD_PROJECT"]
    except KeyError:
        pass

    try:
        return os.environ["GCP_PROJECT"]
    except KeyError:
        pass

    try:
        return os.environ["PROJECT_ID"]
    except KeyError:
        raise ValueError(
            "GCP project not set in environment variables. "
            "Please set GCP_PROJECT, GOOGLE_CLOUD_PROJECT, "
            "or PROJECT_ID."
        )


def get_secret_by_name(
    name: str,
    project: str = "",
    client=secretmanager.SecretManagerServiceClient(),
) -> str:
    project = project or get_gcp_project_id()

    version = f"projects/{project}/secrets/{name}/versions/latest"
    response = client.access_secret_version(name=version)
    return response.payload.data.decode("UTF-8").strip()


def get_secrets_by_label(
    label: str,
    project: str = "",
    client=secretmanager.SecretManagerServiceClient(),
) -> Mapping[str, str]:
    secret_values = {}
    project = project or get_gcp_project_id()

    # once we get on at least 2.0.0 of secret manager, we can filter server-side
    for secret in client.list_secrets(parent=f"projects/{project}"):
        if label in secret.labels:
            version = f"{secret.name}/versions/latest"
            response = client.access_secret_version(name=version)
            secret_values[secret.name.split("/")[-1]] = response.payload.data.decode(
                "UTF-8"
            ).strip()

    return secret_values


if __name__ == "__main__":
    print("loading secrets...")
    get_secret_by_name("BEAR_TRANSIT_KEY")
    print(get_secrets_by_label("gtfs_schedule").keys())
    print(get_secrets_by_label("gtfs_rt").keys())
