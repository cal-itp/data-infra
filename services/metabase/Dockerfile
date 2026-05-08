FROM metabase/metabase:v0.58.7

RUN apk update && apk add --no-cache socat

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
