# --- Étape 1 : installation des dépendances ---
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Étape 2 : image finale, minimale ---
FROM python:3.12-slim
ARG APP_VERSION=dev
ARG GIT_SHA=local
ENV APP_VERSION=$APP_VERSION \
    GIT_SHA=$GIT_SHA \
    DB_PATH=/data/telemetry.db \
    PYTHONUNBUFFERED=1
LABEL org.opencontainers.image.source="https://github.com/konezie127-arch/telemetryhub"

RUN useradd --uid 10001 --create-home appuser \
    && mkdir /data && chown appuser /data

COPY --from=builder /install /usr/local
WORKDIR /srv
COPY app ./app

USER appuser
EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
