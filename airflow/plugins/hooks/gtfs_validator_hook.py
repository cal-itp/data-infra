import json
import os
import subprocess
import tempfile
from typing import Self

import pendulum

from airflow.hooks.base import BaseHook


class GTFSValidatorResult:
    def __init__(
        self,
        version: str,
        current_date: pendulum.DateTime,
        download_schedule_feed_results: dict,
    ) -> None:
        self.version = version
        self.current_date = current_date
        self.download_schedule_feed_results = download_schedule_feed_results
        self._exception = None
        self.report = {}
        self.system_errors = {}

    def read_report(self, report_path: str) -> str:
        with open(report_path, "r") as report_file:
            self.report = json.load(report_file)

    def read_system_errors(self, system_errors_path: str) -> str:
        with open(system_errors_path, "r") as system_errors_file:
            self.system_errors = json.load(system_errors_file)

    def filename(self) -> str:
        return f"validation_notices_v{self.version.replace('.', '-')}.jsonl.gz"

    def metadata(self) -> dict:
        return {
            "gtfs_validator_version": f"v{self.version}",
            "extract_config": self.download_schedule_feed_results["config"],
        }

    def notices(self) -> list:
        return [
            {"metadata": self.metadata(), **n} for n in self.report.get("notices", [])
        ]

    def set_exception(self, exception: Exception) -> None:
        self._exception = exception

    def exception(self) -> str:
        return str(self._exception) if self._exception is not None else None

    def success(self) -> bool:
        return self._exception is None

    def validation(self) -> dict:
        return {
            "filename": self.filename(),
            "system_errors": self.system_errors,
            "validator_version": f"v{self.version}",
            "extract_config": self.download_schedule_feed_results["config"],
            "ts": self.current_date.isoformat(),
        }

    def results(self) -> dict:
        return {
            "validation": self.validation(),
            "extract": self.download_schedule_feed_results["extract"],
            "success": self.success(),
            "exception": self.exception(),
        }


class GTSFValidatorVersion:
    JAR_PATH = os.path.normpath(
        os.path.join(os.path.dirname(os.path.realpath(__file__)), "../gtfs_validator")
    )
    VERSIONS = [
        {
            "date": pendulum.datetime(2000, 1, 1),
            "number": "2.0.0",
            "filename": "gtfs-validator-2.0.0-cli.jar",
        },
        {
            "date": pendulum.datetime(2022, 9, 15),
            "number": "3.1.1",
            "filename": "gtfs-validator-3.1.1-cli.jar",
        },
        {
            "date": pendulum.datetime(2022, 11, 16),
            "number": "4.0.0",
            "filename": "gtfs-validator-4.0.0-cli.jar",
        },
        {
            "date": pendulum.datetime(2023, 9, 1),
            "number": "4.1.0",
            "filename": "gtfs-validator-4.1.0-cli.jar",
        },
        {
            "date": pendulum.datetime(2024, 1, 20),
            "number": "4.2.0",
            "filename": "gtfs-validator-4.2.0-cli.jar",
        },
        {
            "date": pendulum.datetime(2024, 3, 27),
            "number": "5.0.0",
            "filename": "gtfs-validator-5.0.0-cli.jar",
        },
    ]

    def __init__(self, date: pendulum.DateTime, number: str, filename: str) -> None:
        self.date = date
        self.number = number
        self.filename = filename

    @staticmethod
    def all() -> list[Self]:
        return [__class__(**v) for v in __class__.VERSIONS]

    @staticmethod
    def find(current_date: pendulum.DateTime) -> Self:
        return [v for v in __class__.all() if v.date < current_date][-1]

    def __str__(self) -> str:
        return self.number

    def path(self) -> str:
        return os.path.join(__class__.JAR_PATH, self.filename)

    def run(
        self,
        current_date: pendulum.DateTime,
        input_zip: str,
        download_schedule_feed_results: dict,
    ) -> None:
        with tempfile.TemporaryDirectory() as output_dir:
            args = [
                "java",
                "-jar",
                self.path(),
                "--input",
                input_zip,
                "--output_base",
                output_dir,
                "--feed_name" if self.number == "2.0.0" else "--country_code",
                "us-na",
            ]

            result = GTFSValidatorResult(
                current_date=current_date,
                version=self.number,
                download_schedule_feed_results=download_schedule_feed_results,
            )

            try:
                subprocess.run(args, capture_output=True, check=True)
                result.read_report(os.path.join(output_dir, "report.json"))
                result.read_system_errors(
                    os.path.join(output_dir, "system_errors.json")
                )
            except Exception as e:
                result.set_exception(e)

            return result


class GTFSValidatorHook(BaseHook):
    date: pendulum.DateTime

    def __init__(self, date: pendulum.DateTime):
        super().__init__()
        self.date = date

    def version(self) -> str:
        return GTSFValidatorVersion.find(self.date)

    def run(
        self, filename: str, download_schedule_feed_results: dict
    ) -> GTFSValidatorResult:
        return self.version().run(
            current_date=self.date,
            download_schedule_feed_results=download_schedule_feed_results,
            input_zip=filename,
        )
