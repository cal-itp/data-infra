from pathlib import Path

import toml
from gtfs_schedule_validator_hourly import __version__


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
