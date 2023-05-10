# syntax = edrevo/dockerfile-plus

INCLUDE+ ./Dockerfile.local

COPY . /app

CMD ["dbt", "run", "--project-dir", "/app", "--profiles-dir", "/app"]
