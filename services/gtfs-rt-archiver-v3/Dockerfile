FROM --platform=linux/amd64 python:3.9 as build

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

RUN apt-get update && apt-get install -y libunwind-dev liblz4-dev

COPY ./ssl /usr/local/share/ca-certificates/custom
RUN update-ca-certificates

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt \
    && pip install -r requirements.txt
RUN pip install memray

COPY . /app

CMD ["python3", "-m", "gtfs_rt_archiver_v3"]
