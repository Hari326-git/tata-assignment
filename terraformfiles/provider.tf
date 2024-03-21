terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.8.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}


provider "google" {
  region      = "asia-south2"
  project     = "valid-moment-410717"
  credentials = file("cred.json")
  zone        = "asia-south2-a"

}
