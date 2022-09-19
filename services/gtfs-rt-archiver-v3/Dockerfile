FROM python:3.9

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python -
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt \
    && pip install -r requirements.txt
RUN pip install memray

COPY . /app

CMD ["python3", "-m", "gtfs_rt_archiver_v3"]
