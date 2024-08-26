terraform {
  required_version = ">= 1.2.4"

  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
    tls      = "~> 3.1.0"
    random   = "~> 3.1.0"
    null     = "~> 3.1.0"
    external = "~> 2.2.0"
    http     = "~> 2.1.0"
    local    = "~> 2.1.0"
  }

  backend "gcs" {
  }

  # backend "local" {
  #   path = "terraform.tfstate"
  # }
}
