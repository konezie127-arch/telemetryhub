# Architecture

## Vue d'ensemble de l'infrastructure

```mermaid
flowchart LR
  user["Utilisateur"]
  subgraph GH["GitHub"]
    repo["Depot Git"]
    ci["GitHub Actions"]
    ghcr["GHCR : registre d'images"]
  end
  subgraph AWS["AWS eu-north-1"]
    iam["Role IAM temporaire via OIDC"]
    ssm["SSM Run Command"]
    s3[("S3 : etat Terraform")]
    subgraph VPC["VPC dedie"]
      subgraph EC2["Instance EC2 + IP elastique"]
        nginx["Nginx port 80"]
        app["Application FastAPI port 8000"]
        vol[("Volume SQLite")]
      end
    end
  end
  user -->|"HTTP"| nginx
  nginx --> app
  app --> vol
  repo --> ci
  ci -->|"push image"| ghcr
  ci -->|"jeton OIDC"| iam
  iam --> ssm
  ssm -->|"deploy.sh sha"| EC2
  EC2 -->|"pull image"| ghcr
```

## Chaine de deploiement

```mermaid
sequenceDiagram
  actor Dev
  participant GH as GitHub Actions
  participant REG as GHCR
  participant AWS as AWS OIDC et SSM
  participant SRV as Serveur deploy.sh
  Dev->>GH: Pull request : lint, tests, build, smoke test
  Dev->>GH: Fusion sur main
  GH->>GH: Build de l'image et scan Trivy
  GH->>REG: Push de l'image taguee par SHA
  GH->>AWS: Jeton OIDC puis role temporaire
  GH->>SRV: SSM Run Command deploy.sh SHA
  SRV->>REG: Pull de l'image
  SRV->>SRV: Demarrage, health, version egale au SHA
  alt Version saine
    SRV-->>GH: Success
  else Echec
    SRV->>SRV: Rollback vers la version precedente
    SRV-->>GH: Failed, job rouge
  end
  GH->>SRV: Verification externe de /version
```

## Choix techniques

| Besoin | Choix | Raison |
|---|---|---|
| Cloud | AWS, region eu-north-1 | Compte disponible, profil cible du projet |
| Infrastructure | Terraform, etat dans S3 avec verrou | Reproductible, historise, verrou contre les ecritures concurrentes |
| Configuration | Ansible | Idempotent, installe Docker et l'application |
| Conteneurs | Docker multi-etapes, utilisateur non root | Image reduite, surface d'attaque limitee |
| CI/CD | GitHub Actions | Integre au depot, OIDC natif vers AWS |
| Acces du pipeline a AWS | OIDC + SSM Run Command | Aucune cle longue duree, aucun port SSH ouvert pour le deploiement |
| Images | Tag par SHA, jamais `latest` en production | Deploiement et retour arriere deterministes |

## Securite

- Role de deploiement limite a ce depot **et** a la branche `main` (sub OIDC immuable), droits SSM limites a l'instance.
- Scan Trivy bloquant (CRITICAL et HIGH) avant toute publication.
- Actions GitHub epinglees par SHA, mises a jour par Dependabot.
- Etat Terraform chiffre, versionne, sans acces public. Aucun secret dans le depot.

## Limites connues

- Indisponibilite d'environ 1 s par deploiement (recreation du conteneur) : un deploiement bleu/vert la supprimerait.
- Donnees SQLite stockees sur l'instance : perdues lors d'une reconstruction (volume EBS ou base geree en production).
- Ansible utilise SSH : necessite l'adresse IP de l'administrateur dans le groupe de securite (piloter Ansible par SSM l'eviterait).
- Etape Ansible dominante dans la reconstruction (87 s sur 159 s) : une AMI pre-construite la reduirait.
