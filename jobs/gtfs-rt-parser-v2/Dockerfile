FROM openjdk:11

LABEL org.opencontainers.image.source=https://github.com/cal-itp/data-infra

ENV GTFS_RT_VALIDATOR_JAR=/gtfs-realtime-validator.jar
ENV GTFS_RT_VALIDATOR_VERSION=v1.0.0

RUN apt-get update -y \
    && apt-get install -y python3 python3-pip python3-venv libunwind-dev liblz4-dev

RUN curl -sSL https://install.python-poetry.org | POETRY_VERSION=2.0.1 python -
ENV PATH="/root/.local/bin:${PATH}"
RUN poetry self add poetry-plugin-export@1.9.0
# from https://github.com/MobilityData/gtfs-realtime-validator/packages/1268973
COPY ./gtfs-realtime-validator-lib-1.0.0-20220223.003525-2.jar ${GTFS_RT_VALIDATOR_JAR}

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt \
    && pip install -r requirements.txt
RUN pip install memray

COPY . /app

CMD ["python3", "wrapper.py", "--help"]
