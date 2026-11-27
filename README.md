# TelemetryHub

API FastAPI de collecte de mesures capteurs, déployée sur AWS via une chaîne
CI/CD automatisée (GitHub Actions, Docker, Terraform, Ansible).

## Lancer en local
    docker compose up --build -d
    curl http://localhost/health

## Tests
    pip install -r requirements-dev.txt
    pytest -v
