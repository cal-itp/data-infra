from typing import Mapping

from google.cloud import secretmanager  # type: ignore

project = "projects/cal-itp-data-infra"


def get_secret_by_name(
    name: str,
    client=secretmanager.SecretManagerServiceClient(),
) -> str:
    version = f"{project}/secrets/{name}/versions/latest"
    response = client.access_secret_version(name=version)
    return response.payload.data.decode("UTF-8").strip()


def get_secrets_by_label(
    label: str,
    client=secretmanager.SecretManagerServiceClient(),
) -> Mapping[str, str]:
    secret_values = {}

    # once we get on at least 2.0.0 of secret manager, we can filter server-side
    for secret in client.list_secrets(parent=project):
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
