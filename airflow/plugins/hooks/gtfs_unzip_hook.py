import hashlib
import os
import zipfile

import pendulum

from airflow.hooks.base import BaseHook


class GTFSUnzipResult:
    def __init__(
        self,
        download_schedule_feed_results: dict,
        current_date: pendulum.DateTime,
    ) -> None:
        self.download_schedule_feed_results = download_schedule_feed_results
        self.current_date = current_date
        self._exception = None
        self._md5hash = hashlib.md5()
        self._files = []
        self._directories = []
        self._content_name = None
        self._content_original_name = None
        self._content = None

    def valid(self) -> bool:
        if not self._directories:
            return True
        if len(self._directories) == 1 and all(
            [f.startswith(self._directories[0]) for f in self._files]
        ):
            return True
        return False

    def success(self) -> bool:
        return self._exception is None

    def exception(self) -> bool:
        return str(self._exception) if self._exception is not None else None

    def extract(self) -> dict:
        return self.download_schedule_feed_results.get("extract")

    def extract_config(self) -> dict:
        return self.download_schedule_feed_results.get("extract").get("config")

    def add_exception(self, exception: Exception) -> None:
        self._exception = exception

    def add_file(self, file) -> None:
        self._files.append(file)

    def add_directory(self, directory) -> None:
        self._directories.append(directory)

    def add_hash(self, content: bytes) -> None:
        self._md5hash.update(content)

    def add_content(self, name: str, original_name: str, content: bytes) -> None:
        self._content_name = name
        self._content_original_name = original_name
        self._content = content

    def files(self) -> list[str]:
        return sorted(self._files)

    def directories(self) -> list[str]:
        return sorted(self._directories)

    def content(self) -> bytes:
        return self._content

    def md5hash(self) -> str:
        return self._md5hash.hexdigest()

    def extracted_files(self) -> list[str]:
        if self._content_name is None:
            return []
        return [
            {
                "filename": self._content_name,
                "original_filename": self._content_original_name,
                "ts": self.current_date.isoformat(),
                "extract_config": self.extract_config(),
            }
        ]

    def results(self) -> dict:
        return {
            "success": self.success(),
            "exception": self.exception(),
            "extract": self.extract(),
            "zipfile_extract_md5hash": self.md5hash(),
            "zipfile_files": self.files(),
            "zipfile_dirs": self.directories(),
            "extracted_files": self.extracted_files(),
        }


class GTFSZip:
    MACOSX_ZIP_FOLDER = "__MACOSX"

    filename: str

    def __init__(self, filename: str) -> None:
        self.filename = filename

    def extract(self, path_to_extract: str, result: GTFSUnzipResult) -> None:
        with zipfile.ZipFile(self.filename, "r") as zip_file:
            for name in zip_file.namelist():
                if name.startswith("__MACOSX"):
                    pass
                elif zipfile.Path(root=zip_file, at=name).is_dir():
                    result.add_directory(name)
                elif zipfile.Path(root=zip_file, at=name).is_file():
                    result.add_file(name)

            for file_path in result.files():
                with zip_file.open(file_path) as child_file:
                    content = child_file.read()
                    result.add_hash(content)
                    if (
                        result.valid()
                        and os.path.basename(file_path) == path_to_extract
                    ):
                        result.add_content(
                            name=path_to_extract,
                            original_name=file_path,
                            content=content,
                        )


class GTFSUnzipHook(BaseHook):
    filename: str
    current_date: pendulum.DateTime

    def __init__(self, filename: str, current_date: pendulum.DateTime):
        super().__init__()
        self.filename = filename
        self.current_date = current_date

    def run(
        self, zipfile_path: str, download_schedule_feed_results: dict
    ) -> GTFSUnzipResult:
        result = GTFSUnzipResult(
            current_date=self.current_date,
            download_schedule_feed_results=download_schedule_feed_results,
        )

        try:
            GTFSZip(filename=zipfile_path).extract(
                path_to_extract=self.filename, result=result
            )
            if not result.valid():
                raise ValueError(
                    "Unparseable zip: File/directory structure within zipfile cannot be unpacked"
                )

        except Exception as e:
            result.add_exception(e)

        return result
