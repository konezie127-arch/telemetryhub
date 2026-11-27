# Pipeline CI/CD

| Workflow | Declencheur | Role |
|---|---|---|
| `ci.yml` | Pull request | Lint (ruff), tests (pytest), build Docker et smoke test. Checks `test` et `docker-build` obligatoires |
| `publish.yml` | Push sur `main` | Job `publish` : build, scan Trivy, push GHCR. Job `deploy` : appelle `deploy.yml` |
| `deploy.yml` | Appel par `publish.yml` ou lancement manuel | Authentification OIDC, deploiement via SSM, verification externe |

## Regles

- `main` est protegee : tout changement passe par une pull request dont les checks sont verts.
- Une image n'est publiee que si le scan Trivy ne trouve aucune vulnerabilite CRITICAL ou HIGH corrigeable.
- Le tag deploye est toujours le SHA court du commit. Un seul deploiement a la fois (`concurrency`).
- Le tag est valide par expression regulière avant usage, et passe par une variable d'environnement (pas d'injection de commande).

## Logique de `deploy/deploy.sh` (sur le serveur)

1. Verrou `flock` : refus d'un second deploiement simultane.
2. Si la version demandee est deja en ligne et saine : `NOCHANGE`.
3. Sinon : pull de l'image, `docker compose up -d`, puis controle de `/health` **a travers Nginx** et de `/version` (le SHA doit correspondre).
4. En cas d'echec : retour automatique a la version precedente, puis sortie en code 1 (le job devient rouge, l'echec n'est jamais masque).

## Rollback manuel

Actions, workflow **Deploy**, Run workflow, branche `main`, tag de la version voulue. Duree mesuree : environ 30 s.

## Configuration requise dans GitHub

Variable de depot `AWS_DEPLOY_ROLE_ARN` (onglet **Variables**, pas Secrets).
