from pathlib import Path

import pendulum

from gtfs_rt_parser import RTFile, RTFileTypePrefix, RTFileType


def test_get_google_cloud_filename() -> None:
    assert RTFile(
        prefix=RTFileTypePrefix.rt,
        file_type=RTFileType.vehicle_positions,
        path=Path("gs://some-random-bucket/some/random/path/my_file"),
        itp_id=1,
        url=2,
        tick=pendulum.parse('2022-04-05T22:00:00'),
    ).hive_path(
        bucket="gs://some-random-bucket") == "gs://some-random-bucket/vehicle_positions/dt=2022-04-05/itp_id=1/url=2/hour=22/minute=0/second=0/my_file"
