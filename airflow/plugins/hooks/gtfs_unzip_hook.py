import hashlib
import logging
import os
import zipfile

from airflow.hooks.base import BaseHook


class GTFSExtractedFile:
    def __init__(
        self,
        current_date: str,
        config: dict[str, str],
        filename: str,
        original_filename: str,
        content: bytes,
    ) -> None:
        self.filename = filename
        self.original_filename = original_filename
        self.content = content
        self.current_date = current_date
        self.config = config

    def metadata(self) -> dict[str, str]:
        return {
            "filename": self.filename,
            "original_filename": self.original_filename,
            "ts": self.current_date,
            "extract_config": self.config,
        }


class GTFSUnzipResult:
    def __init__(
        self,
        download_schedule_feed_results: dict,
        current_date: str,
    ) -> None:
        self.download_schedule_feed_results = download_schedule_feed_results
        self.current_date = current_date
        self._exception = None
        self._md5hash = hashlib.md5()
        self._files = []
        self._directories = []
        self._extracted_files = []

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

    def add_content(self, name: str, original_filename: str, content: bytes) -> None:
        self._extracted_files.append(
            GTFSExtractedFile(
                filename=name,
                original_filename=original_filename,
                content=content,
                config=self.extract_config(),
                current_date=self.current_date,
            )
        )

    def files(self) -> list[str]:
        return sorted(self._files)

    def directories(self) -> list[str]:
        return sorted(self._directories)

    def md5hash(self) -> str:
        return self._md5hash.hexdigest()

    def extracted_files(self) -> list[GTFSExtractedFile]:
        return self._extracted_files

    def results(self) -> dict:
        return {
            "success": self.success(),
            "exception": self.exception(),
            "extract": self.extract(),
            "zipfile_extract_md5hash": self.md5hash(),
            "zipfile_files": self.files(),
            "zipfile_dirs": self.directories(),
            "extracted_files": [ef.metadata() for ef in self.extracted_files()],
        }


class GTFSZip:
    MACOSX_ZIP_FOLDER = "__MACOSX"

    filename: str

    def __init__(self, filename: str) -> None:
        self.filename = filename

    def extract(self, filenames: str, result: GTFSUnzipResult) -> None:
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
                    filename = os.path.basename(file_path)
                    if result.valid() and filename in filenames:
                        result.add_content(
                            name=filename,
                            original_filename=file_path,
                            content=content,
                        )


class GTFSUnzipHook(BaseHook):
    filenames: list[str]
    current_date: str

    def __init__(self, filenames: list[str], current_date: str):
        super().__init__()
        self.filenames = filenames
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
                filenames=self.filenames, result=result
            )
            if not result.valid():
                raise ValueError(
                    "Unparseable zip: File/directory structure within zipfile cannot be unpacked"
                )

        except Exception as e:
            result.add_exception(e)
            logging.error(str(e))

        return result
