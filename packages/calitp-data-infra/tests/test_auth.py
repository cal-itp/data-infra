from unittest.mock import patch

import pytest
from calitp_data_infra.auth import get_gcp_project_id


def test_get_gcp_project_id() -> None:
    """
    Test the get_gcp_project_id function.
    """
    import os

    with patch.dict(os.environ, {"GOOGLE_CLOUD_PROJECT": "test-project"}):
        project_id = get_gcp_project_id()

    assert project_id == "test-project"


def test_get_gcp_project_id_no_env() -> None:
    """
    Test the get_gcp_project_id function when no environment variable is set.
    """
    # Remove the environment variable for testing
    import os

    with patch.dict("os.environ"):
        os.environ.pop("GOOGLE_CLOUD_PROJECT", None)
        os.environ.pop("GCP_PROJECT", None)
        os.environ.pop("PROJECT_ID", None)

        with pytest.raises(ValueError):
            get_gcp_project_id()
