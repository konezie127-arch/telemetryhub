# TelemetryHub : Cloud DevOps et Infrastructure as Code

Projet de fin d'etudes (cloud computing) : une application FastAPI de collecte de mesures de capteurs, livree par un pipeline CI/CD complet sur AWS, avec une infrastructure entierement decrite en code.

## Ce que le projet demontre

- **Versionnement** : Git, pull requests obligatoires, branche `main` protegee.
- **CI/CD** : GitHub Actions (tests, lint, build, scan Trivy, publication, deploiement).
- **Infrastructure as Code** : Terraform (reseau, calcul, IAM) et Ansible (configuration du serveur).
- **Deploiement sur** : AWS, avec controle de sante et **retour arriere automatique**.
- **Reconstruction complete** en 2 min 40 s a partir des seuls fichiers du depot.

## Resultats mesures

| Mesure | Valeur |
|---|---|
| Commit fusionne vers production | environ 1 min 30 s |
| Rollback manuel | environ 30 s |
| Reconstruction complete (0 action manuelle) | 2 min 39 s |
| Indisponibilite pendant un deploiement | environ 1 s |

Detail dans [docs/mesures.md](docs/mesures.md).

## Documentation

- [Architecture et choix techniques](docs/architecture.md)
- [Pipeline CI/CD](docs/pipeline.md)
- [Runbook : reconstruction et incidents](docs/runbook.md)
- [Mesures et experiences](docs/mesures.md)

## Structure du depot

| Dossier | Contenu |
|---|---|
| `app/`, `tests/` | Application FastAPI et tests pytest |
| `docker/`, `docker-compose.yml` | Image multi-etapes et pile locale |
| `deploy/` | Compose de production, Nginx, `deploy.sh` (deploiement et rollback) |
| `terraform/` | Infrastructure AWS (`bootstrap/` pour l'etat distant) |
| `ansible/` | Configuration du serveur (Docker, application) |
| `scripts/` | Reconstruction, inventaire, epinglage des actions, mesure de disponibilite |
| `.github/workflows/` | `ci.yml`, `publish.yml`, `deploy.yml` |

## Demarrage local

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
ruff check . && pytest -q
docker compose up --build        # application sur http://localhost
```

## Limites et pistes d'amelioration

Voir la section « Limites connues » de [docs/architecture.md](docs/architecture.md).
