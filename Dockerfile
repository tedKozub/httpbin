# 1 build stage
FROM cgr.dev/chainguard/python:latest-dev AS builder

USER root
WORKDIR /build

ENV PATH="/app/venv/bin:$PATH"

RUN python -m venv /app/venv \
 && pip install --no-cache-dir --upgrade pip

COPY setup.py MANIFEST.in ./
COPY httpbin/ ./httpbin/

RUN pip install --no-cache-dir gunicorn . \
 && find /app/venv -type d \( -name "__pycache__" -o -name "tests" -o -name "test" \) -prune -exec rm -rf {} +

# 2 runtime stage

FROM cgr.dev/chainguard/python:latest

ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/venv/bin:$PATH"

LABEL name="httpbin" \
      version="0.9.2" \
      description="A simple HTTP service." \
      org.kennethreitz.vendor="Kenneth Reitz" \
      org.opencontainers.image.title="httpbin" \
      org.opencontainers.image.description="A simple HTTP request & response service." \
      org.opencontainers.image.source="https://github.com/postmanlabs/httpbin" \
      org.opencontainers.image.licenses="ISC"

COPY --from=builder --chown=nonroot:nonroot /app/venv /app/venv

WORKDIR /app

USER nonroot

EXPOSE 8080

ENTRYPOINT ["gunicorn"]
CMD ["-b", "0.0.0.0:8080", "-k", "gevent", "httpbin:app"]
