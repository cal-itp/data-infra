import pytest


@pytest.fixture(scope="module")
def vcr_config():
    return {
        "allow_playback_repeats": True,
        "filter_headers": [
            ("cookie", "FILTERED"),
            ("Authorization", "FILTERED"),
            ("apikey", "FILTERED"),
            ("X-CKAN-API-Key", "FILTERED"),
            ("Granicus-Auth", "FILTERED"),
        ],
        "filter_query_parameters": [
            ("api_key", "FILTERED"),
        ],
        "ignore_hosts": [
            "run-actions-1-azure-eastus.actions.githubusercontent.com",
            "run-actions-2-azure-eastus.actions.githubusercontent.com",
            "run-actions-3-azure-eastus.actions.githubusercontent.com",
            "sts.googleapis.com",
            "iamcredentials.googleapis.com",
            "oauth2.googleapis.com",
        ],
    }
