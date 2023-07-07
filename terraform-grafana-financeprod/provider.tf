terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.70.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    /*helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }*/
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "google" {
  project = "celero-finance-production"
  region  = "southamerica-east1-c"
}
