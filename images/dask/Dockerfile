FROM ghcr.io/dask/dask:2022.10.0-py3.10

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

# TODO: move back to poetry once we shrink the dependcies...
#COPY ./pyproject.toml /reqs/pyproject.toml
#COPY ./poetry.lock /reqs/poetry.lock
#RUN poetry config virtualenvs.create false
#RUN cd /reqs && poetry install
COPY ./requirements.txt /reqs/requirements.txt
RUN pip install -r /reqs/requirements.txt
