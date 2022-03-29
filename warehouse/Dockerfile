FROM python:3.7-buster

RUN mkdir /app
WORKDIR /app
COPY . /app

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
ENV PATH="${PATH}:/root/.poetry/bin"

RUN poetry export -f requirements.txt --output requirements.txt \
    && pip install -r requirements.txt

CMD ["dbt", "run", "--project-dir", "/app", "--profiles-dir", "/app"]
