FROM openjdk:11

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

ENV GTFS_RT_VALIDATOR_JAR=/gtfs-realtime-validator.jar
ENV GTFS_RT_VALIDATOR_VERSION=v1.0.0

RUN apt-get update -y \
    && apt-get install -y python3 python3-pip python3-venv

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python3 -
ENV PATH="/root/.local/bin:${PATH}"

# formerly the "1.0.0-SNAPSHOT" from S3
COPY ./rt-validator-v1.0.0_cli.jar ${GTFS_RT_VALIDATOR_JAR}

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt \
    && pip install -r requirements.txt
RUN pip install memray

COPY . /app

CMD ["python3", "wrapper.py", "--help"]
