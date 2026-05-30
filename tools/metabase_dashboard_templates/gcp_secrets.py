"""GCP Secret Manager access for the Metabase dashboard template tool.

Fetches the Metabase API key from Secret Manager via Application Default
Credentials, transparently running `gcloud auth application-default login`
when ADC is missing.  Errors are surfaced as click.ClickException so the CLI
prints them cleanly without a traceback.
"""

import shutil
import subprocess

import click


def _run_gcloud_adc_login() -> None:
    """Shell out to `gcloud auth application-default login`.

    Used when ADC are missing so the user doesn't have to drop out of the
    wizard to run it themselves.  Inherits stdio so the gcloud browser flow
    works normally (gcloud prints a URL, the user signs in, control returns).
    """
    if shutil.which("gcloud") is None:
        raise click.ClickException(
            "gcloud CLI not found on PATH.  Install the Google Cloud SDK "
            "(https://cloud.google.com/sdk/docs/install) and try again."
        )
    click.echo(
        "Launching `gcloud auth application-default login` "
        "(a browser tab will open)...",
        err=True,
    )
    try:
        subprocess.run(["gcloud", "auth", "application-default", "login"], check=True)
    except subprocess.CalledProcessError as exc:
        raise click.ClickException(
            f"`gcloud auth application-default login` failed "
            f"(exit code {exc.returncode})."
        )
    except KeyboardInterrupt:
        raise click.ClickException("Login cancelled.")


def fetch_secret_from_gcp(secret_resource_name: str) -> str:
    """Fetch a secret payload from GCP Secret Manager via Application Default Credentials.

    `secret_resource_name` must be a fully-qualified resource name:
        projects/PROJECT_ID/secrets/SECRET_NAME/versions/VERSION
    Use "latest" as VERSION to always get the current active version.

    If ADC is not configured, this transparently runs
    `gcloud auth application-default login` and retries once.  All other
    failures (malformed name, secret missing, permission denied, transport
    errors) raise ClickException with a message that names the secret.
    """
    try:
        from google.api_core import exceptions as gcp_exceptions
        from google.auth import exceptions as auth_exceptions
        from google.cloud import secretmanager
    except ImportError:
        raise click.ClickException(
            "google-cloud-secret-manager is not installed. "
            "Run: pip install google-cloud-secret-manager"
        )

    # Sanity-check the resource name format up front, so a typo gives a
    # clearer error than the server's InvalidArgument.
    parts = secret_resource_name.split("/")
    if (
        len(parts) != 6
        or parts[0] != "projects"
        or parts[2] != "secrets"
        or parts[4] != "versions"
    ):
        raise click.ClickException(
            f"GCP secret resource name is malformed: {secret_resource_name!r}\n"
            "Expected format: "
            "projects/PROJECT_ID/secrets/SECRET_NAME/versions/VERSION "
            "(VERSION may be 'latest')."
        )

    def _build_client():
        return secretmanager.SecretManagerServiceClient()

    try:
        client = _build_client()
    except auth_exceptions.DefaultCredentialsError:
        click.echo(
            "GCP Application Default Credentials are not configured.",
            err=True,
        )
        _run_gcloud_adc_login()
        # Retry once after login completes.  If it still fails here, the
        # exception propagates -- something deeper is wrong (e.g. login
        # succeeded but the credential file is unreadable).
        client = _build_client()

    try:
        response = client.access_secret_version(name=secret_resource_name)
    except auth_exceptions.RefreshError as exc:
        raise click.ClickException(
            f"GCP credentials are expired or invalid "
            f"(needed to fetch {secret_resource_name!r}): {exc}\n"
            "Refresh and retry.  For cal-itp workforce identity:\n"
            "  glogin-calitp-staging   # or glogin-calitp-prod\n"
            "Or run `gcloud auth application-default login` directly."
        )
    except gcp_exceptions.Unauthenticated as exc:
        raise click.ClickException(
            f"GCP rejected your credentials on {secret_resource_name!r}: {exc}\n"
            "Refresh ADC and retry: see your workforce identity login alias "
            "(e.g. glogin-calitp-staging)."
        )
    except gcp_exceptions.NotFound:
        # Reaching this branch is rare -- GCP usually conflates NotFound and
        # PermissionDenied into the latter to avoid leaking secret names.
        raise click.ClickException(
            f"GCP secret not found: {secret_resource_name!r}\n"
            "Verify with:\n"
            f"  gcloud secrets describe {parts[3]} --project={parts[1]}"
        )
    except gcp_exceptions.PermissionDenied as exc:
        raise click.ClickException(
            f"GCP returned 403 on {secret_resource_name!r}: {exc}\n"
            "This means EITHER the secret does not exist OR your account "
            "lacks secretmanager.versions.access.  GCP intentionally collapses "
            "both into the same error.  To distinguish:\n"
            f"  1. Check existence:\n"
            f"       gcloud secrets describe {parts[3]} --project={parts[1]}\n"
            "  2. If `describe` succeeds, you need the role.  Run:\n"
            f"       gcloud secrets add-iam-policy-binding {parts[3]} \\\n"
            f"         --project={parts[1]} \\\n"
            '         --member="user:$(gcloud config get-value account)" \\\n'
            '         --role="roles/secretmanager.secretAccessor"\n'
            "  3. If `describe` returns NOT_FOUND, the secret hasn't been "
            "created yet -- create it (or ask whoever owns the project to)."
        )
    except gcp_exceptions.GoogleAPICallError as exc:
        raise click.ClickException(
            f"GCP error fetching secret {secret_resource_name!r}: {exc}"
        )

    return response.payload.data.decode("utf-8").strip()
