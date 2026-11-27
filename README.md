# TelemetryHub

API FastAPI de collecte de mesures capteurs, déployée sur AWS via une chaîne
CI/CD automatisée (GitHub Actions, Docker, Terraform, Ansible).

## Lancer en local
    docker compose up --build -d
    curl http://localhost/health

## Tests
    pip install -r requirements-dev.txt
    pytest -v

## Objet
Ajout du pipeline CI GitHub Actions.

## Contenu
- Lint (ruff) et tests (pytest) à chaque push/PR
- Build de l'image Docker + test de fumée sur /health

## Vérification
Les checks `test` et `docker-build` doivent passer au vert.
