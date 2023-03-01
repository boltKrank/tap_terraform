# Google cloud TAP Install
provider "google" {
  project = "{{YOUR GCP PROJECT}}"
  region  = var.region
  zone    = var.zone
}