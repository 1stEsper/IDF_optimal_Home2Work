variable "project_id" {
  description = "idf-analysis"
  type        = string
}

variable "region" {
  description = "US"
  default     = "us-central1"
}

variable "datasets" {
  description = "List of layers to create"
  type        = list(string)
  default     = ["idfm_raw", "geo_raw", "housing_raw", "core", "mart"]
}

variable "bucket_name" {
  description = "idf-analysis-data-lake"
}