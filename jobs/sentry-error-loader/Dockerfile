FROM python:3.9

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

RUN curl -sSL https://install.python-poetry.org | python -
ENV PATH="/root/.local/bin:${PATH}"
ENV CALITP_BUCKET__SENTRY_EVENTS="test-calitp-sentry"

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt \
    && pip install -r requirements.txt

COPY . /app
