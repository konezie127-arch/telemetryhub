mkdir -p docs
cat > docs/mesures.md <<'EOF'
# Mesures et experiences

## Pipeline (GitHub Actions)
| Mesure | Valeur |
|---|---|
| CI sur PR (test + docker-build) | ... s |
| Build + scan + publication (job publish) | 38 s a 65 s |
| Deploiement (job deploy) | 28 s a 37 s |
| Commit fusionne -> version en production | 1 min 22 s a 1 min 48 s |

## Rollback
| Scenario | Duree | Resultat |
|---|---|---|
| Rollback manuel (workflow Deploy, tag precedent) | 29 s | Service restaure, verifie par /version |
| Version defaillante (TrustedHost derriere Nginx) | ... s | Detection, rollback automatique, job rouge, service intact |
| Tag inexistant | ... s | Rollback automatique, statut SSM Failed |

## Reconstruction complete (0 action manuelle)
| Etape | Duree |
|---|---|
| terraform destroy (18 ressources) | 1 min 05 s |
| terraform apply (18 ressources) | 55 s |
| Inventaire Ansible | 5 s |
| Attente de l'instance (SSH) | 7 s |
| Ansible (Docker + application) | 87 s |
| Verification HTTP | 5 s |
| **Total reconstruction** | **159 s** |

## Disponibilite pendant un deploiement
| Mesure | Valeur |
|---|---|
| Requetes OK / indisponibles | ... / ... |
| Duree d'indisponibilite estimee | ... s |

## Securite verifiee
- OIDC : refus depuis une branche autre que main (Deploy #6)
- Actions epinglees par SHA (7 actions), mises a jour par Dependabot
- Scan Trivy bloquant (CRITICAL, HIGH) avant publication
- Verrous : etat Terraform (S3) et deploiement (flock), observes en conditions reelles
EOF
