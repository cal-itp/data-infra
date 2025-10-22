from pathlib import Path

import pytest
import toml
from gtfs_schedule_validator_hourly import __version__, app
from typer.testing import CliRunner


def test_version():
    assert __version__ == "0.1.0"


# from https://github.com/python-poetry/poetry/issues/144#issuecomment-877835259
def test_versions_are_in_sync():
    """Checks if the pyproject.toml and package.__init__.py __version__ are in sync."""

    path = Path(__file__).resolve().parents[0] / "pyproject.toml"
    with open(str(path)) as f:
        pyproject = toml.loads(f.read())
    pyproject_version = pyproject["tool"]["poetry"]["version"]

    package_init_version = __version__

    assert package_init_version == pyproject_version


class TestGtfsScheduleValidator:
    @pytest.fixture
    def runner(self) -> CliRunner:
        return CliRunner()

    def test_no_extracts(self, runner):
        hour_start = "2020-02-20T20:00"
        result = runner.invoke(
            app,
            [
                "validate-hour",
                hour_start,
            ],
        )
        # assert result.exit_code == 0
        assert "found 0 extracts to process, exiting" in result.stdout
