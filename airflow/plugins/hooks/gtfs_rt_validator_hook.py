import json
import logging
import os
import subprocess
import tempfile
from typing import Self

import pendulum

from airflow.hooks.base import BaseHook


class GTFSRTValidatorResult:
    def __init__(self, ts: str, version: str, config: dict) -> None:
        self.ts: str = ts
        self.version: str = version
        self.config: dict = config
        self._exception: Exception = None
        self._output = None
        self._stderr = None
        self._notices = []

    def set_exception(self, exception: Exception) -> None:
        self._exception: Exception = exception

    def set_output(self, output: str) -> None:
        self._output = output

    def set_stderr(self, stderr: str) -> None:
        self._stderr = stderr

    def add_notice(self, notice: str) -> None:
        self._notices = [*self._notices, *json.loads(notice)]

    def notice_metadata(self) -> dict:
        return {
            "gtfs_validator_version": f"v{self.version}",
            "extract_ts": self.ts,
            "extract_config": self.config,
        }

    def notices(self) -> list[dict]:
        return [{"metadata": self.notice_metadata(), **n} for n in self._notices]

    def report(self) -> list[dict]:
        return [{}]

    def report_metadata(self) -> list[dict]:
        return {}


class GTFSRTValidatorVersion:
    JAR_PATH = os.path.realpath(
        os.path.join(os.path.dirname(__file__), "../gtfs_rt_validator")
    )
    VERSIONS = [
        {
            "version_date": pendulum.datetime(2000, 1, 1),
            "number": "1.0.0",
            "filename": "gtfs-realtime-validator-lib-1.0.0-20220223.003525-2.jar",
        },
    ]

    @staticmethod
    def all() -> list[Self]:
        return [__class__(**v) for v in __class__.VERSIONS]

    @staticmethod
    def find(current_date: pendulum.DateTime) -> Self:
        return [v for v in __class__.all() if v.version_date < current_date][-1]

    def __init__(
        self, version_date: pendulum.DateTime, number: str, filename: str
    ) -> None:
        self.version_date = version_date
        self.number = number
        self.filename = filename

    def __str__(self) -> str:
        return self.number

    def path(self) -> str:
        return os.path.join(__class__.JAR_PATH, self.filename)

    def run(
        self,
        ts: str,
        config: dict,
        schedule_path: str,
        feed_directory: str,
        feed_paths: list[str],
    ) -> GTFSRTValidatorResult:
        args = [
            "java",
            "-jar",
            self.path(),
            "-gtfs",
            schedule_path,
            "-gtfsRealtimePath",
            feed_directory,
        ]

        result = GTFSRTValidatorResult(
            ts=ts,
            config=config,
            version=self.number,
        )

        try:
            output = subprocess.run(args, capture_output=True, check=True)
            result.set_output(output.stdout.decode("utf-8"))
            for source_file_path in feed_paths:
                with open(f"{source_file_path}.results.json") as file:
                    result.add_notice(file.read())
        except subprocess.CalledProcessError as e:
            result.set_exception(e)
            result.set_stderr(e.stderr.decode("utf-8"))
            logging.error(str(e))
            raise e
        except Exception as e:
            result.set_exception(e)
            logging.error(str(e))
            raise e

        return result


class GTFSRTValidatorHook(BaseHook):
    def __init__(self):
        super().__init__()

    def version(self, ts: str) -> str:
        return GTFSRTValidatorVersion.find(
            current_date=pendulum.DateTime.fromisoformat(ts)
        )

    def run(
        self,
        ts: str,
        config: dict,
        schedule_path: str,
        feed_directory: str,
        feed_paths: list[str],
    ) -> GTFSRTValidatorResult:
        return self.version(ts=ts).run(
            ts=ts,
            config=config,
            schedule_path=schedule_path,
            feed_directory=feed_directory,
            feed_paths=feed_paths,
        )
