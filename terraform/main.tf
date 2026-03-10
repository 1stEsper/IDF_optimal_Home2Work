terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file("../credentials/idf-analysis-0a1db53d06ba.json")
}

resource "google_bigquery_dataset" "bigquery_layers" {
  for_each   = toset(var.datasets)
  dataset_id = each.value
  location   = var.region

  description                = "Layer ${each.value} to serve for Data Warehouse"
  delete_contents_on_destroy = true

  labels = {
    env        = "dev"
    managed_by = "terraform"
  }
}

resource "google_storage_bucket" "data_lake" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  labels = {
    env     = "dev"
    project = "idf-housing-mobility"
    zone    = "raw"
  }

}
