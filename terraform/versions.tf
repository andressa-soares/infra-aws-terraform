terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  # Backend parcial: valores vem do pipeline (terraform init -backend-config=...).
  # O state remoto e necessario para o "delete" saber o que destruir.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
