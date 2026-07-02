"""GCP Secret Manager access for the Metabase dashboard template tool.

Fetches the Metabase API key from Secret Manager via Application Default
Credentials.  Recoverable failures raise SecretAccessError with an
actionable message; the CLI layer wraps that into a click.ClickException so
it prints cleanly without a traceback.  This module itself stays free of any
CLI dependency.
"""


class SecretAccessError(Exception):
    """A GCP Secret Manager access failed in a way worth explaining to the
    user.  Carries a ready-to-display, actionable message."""


def fetch_secret_from_gcp(secret_resource_name: str) -> str:
    """Fetch a secret payload from GCP Secret Manager via Application Default Credentials.

    `secret_resource_name` must be a fully-qualified resource name:
        projects/PROJECT_ID/secrets/SECRET_NAME/versions/VERSION
    Use "latest" as VERSION to always get the current active version.

    If ADC is not configured, the underlying google client raises; the user
    is expected to authenticate themselves.  Other failures (malformed name,
    secret missing, permission denied, transport errors) raise
    SecretAccessError with a message that names the secret.
    """
    from google.api_core import exceptions as gcp_exceptions
    from google.auth import exceptions as auth_exceptions
    from google.cloud import secretmanager

    # Sanity-check the resource name format up front, so a typo gives a
    # clearer error than the server's InvalidArgument.
    parts = secret_resource_name.split("/")
    if (
        len(parts) != 6
        or parts[0] != "projects"
        or parts[2] != "secrets"
        or parts[4] != "versions"
    ):
        raise SecretAccessError(
            f"GCP secret resource name is malformed: {secret_resource_name!r}\n"
            "Expected format: "
            "projects/PROJECT_ID/secrets/SECRET_NAME/versions/VERSION "
            "(VERSION may be 'latest')."
        )

    # Use the client as a context manager so its gRPC channel is always
    # closed -- on the success path AND on every error path below.  Without
    # this, an early failure (e.g. expired ADC) leaves the channel's
    # non-daemon background threads running, and the interpreter blocks
    # joining them at shutdown, so the process hangs until Ctrl+C.
    with secretmanager.SecretManagerServiceClient() as client:
        try:
            response = client.access_secret_version(name=secret_resource_name)
        except auth_exceptions.RefreshError as exc:
            raise SecretAccessError(
                f"GCP credentials are expired or invalid "
                f"(needed to fetch {secret_resource_name!r}): {exc}\n"
                "Refresh and retry.  For cal-itp workforce identity:\n"
                "  glogin-calitp-staging   # or glogin-calitp-prod\n"
                "Or run `gcloud auth application-default login` directly."
            )
        except gcp_exceptions.Unauthenticated as exc:
            raise SecretAccessError(
                f"GCP rejected your credentials on {secret_resource_name!r}: {exc}\n"
                "Refresh ADC and retry: see your workforce identity login alias "
                "(e.g. glogin-calitp-staging)."
            )
        except gcp_exceptions.NotFound:
            # Reaching this branch is rare -- GCP usually conflates NotFound and
            # PermissionDenied into the latter to avoid leaking secret names.
            raise SecretAccessError(
                f"GCP secret not found: {secret_resource_name!r}\n"
                "Verify with:\n"
                f"  gcloud secrets describe {parts[3]} --project={parts[1]}"
            )
        except gcp_exceptions.PermissionDenied as exc:
            raise SecretAccessError(
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
            raise SecretAccessError(
                f"GCP error fetching secret {secret_resource_name!r}: {exc}"
            )

        return response.payload.data.decode("utf-8").strip()
