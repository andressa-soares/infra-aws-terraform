terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  # Valores do backend vem do pipeline (terraform init -backend-config=...).
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}
