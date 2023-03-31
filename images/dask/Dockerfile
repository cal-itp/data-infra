FROM ghcr.io/dask/dask:2022.10.0-py3.9

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

# TODO: can we use the jupyter pyproject directly?
COPY ./requirements.txt /reqs/requirements.txt
RUN pip install -r /reqs/requirements.txt
