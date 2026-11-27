terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "telemetryhub-tfstate-015904252134"
    key          = "telemetryhub/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true # verrouillage natif S3 : évite deux apply simultanés
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}
