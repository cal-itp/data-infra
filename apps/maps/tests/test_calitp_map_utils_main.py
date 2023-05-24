import base64
import gzip
import json

import pytest
from calitp_map_utils.cli import app
from typer.testing import CliRunner

runner = CliRunner()


@pytest.mark.slow
def test_validate_state_cli_executes():
    state_dict = {
        "layers": [
            {
                "name": "LA Metro Bus Speed Maps AM Peak",
                "url": "https://storage.googleapis.com/calitp-map-tiles/metro_am.geojson.gz",
            }
        ]
    }
    compressed_encoded = base64.urlsafe_b64encode(
        gzip.compress(json.dumps(state_dict).encode())
    )
    result = runner.invoke(
        app,
        [
            "validate-state",
            "--base64url",
            "--compressed",
            "--data",
        ],
        input=compressed_encoded,
    )
    assert result.exit_code == 0
    assert "Validation successful!" in result.stdout
