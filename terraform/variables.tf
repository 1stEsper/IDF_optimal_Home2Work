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
  default     = ["bronze_raw", "silver_stg", "silver_core", "gold_mart"]
}

variable "bucket_name" {
  description = "idf-analysis-data-lake"
}