"""Regression test for #5334 — Composer 3 ships a Google-patched urllib3
whose _GzipDecoder.decompress() rejects the max_length kwarg urllib3
itself passes, breaking every gzip'd GCS download (e.g. manifest.json
via GCSHook). The urllib3<2.0 pin avoids that build; these tests fail
if it sneaks back in."""

import gzip
import io

import pytest
from urllib3.response import HTTPResponse


def _gzipped(data: bytes) -> bytes:
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb") as f:
        f.write(data)
    return buf.getvalue()


@pytest.fixture
def gzipped_response():
    payload = b'{"nodes": [' + b'{"k":"v"},' * 1000 + b"{}]}"
    return payload, HTTPResponse(
        body=io.BytesIO(_gzipped(payload)),
        headers={"Content-Encoding": "gzip"},
        preload_content=False,
    )


def test_gzip_decode_via_data_property(gzipped_response):
    """resp.data path — preload + decode in one shot."""
    payload, resp = gzipped_response
    assert resp.data == payload


def test_gzip_decode_via_stream(gzipped_response):
    """resp.stream(decode_content=True) — the path GCSHook.download uses."""
    payload, resp = gzipped_response
    assert b"".join(resp.stream(8192, decode_content=True)) == payload
