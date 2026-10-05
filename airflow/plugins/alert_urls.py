from urllib.parse import quote, urlparse

CALTRANS_WORKFORCE_PROVIDER = (
    "locations/global/workforcePools/dot-ca-gov/providers/dot-gcp"
)


def caltrans_sso_log_url(log_url: str) -> str:
    # workforce identity (Caltrans SSO) users can only sign in on the byoid twin of
    # the log host, and only via the sign-in flow with their provider pre-filled
    host = urlparse(log_url).netloc
    unique_id, _, rest = host.partition("-dot-")
    region, _, domain = rest.partition(".composer.")
    if domain != "googleusercontent.com":
        return log_url
    byoid_url = log_url.replace(
        ".composer.googleusercontent.com", ".composer.byoid.googleusercontent.com", 1
    )
    signin_url = (
        f"https://{region}.composer.cloud.google/_signin"
        f"?continue={quote(byoid_url, safe='')}&endpoint={unique_id}"
    )
    return (
        f"https://auth.cloud.google/signin/{CALTRANS_WORKFORCE_PROVIDER}"
        f"?continueUrl={quote(signin_url, safe='')}"
    )
