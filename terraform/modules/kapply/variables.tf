# Input variable definitions

variable "manifest_url" {
  description = "Url of a multi-docs YAML file. The first file should be a namespace."
  type        = string
}

variable "namespace" {
  description = "Namespace to deploy into. Do not set it if the manifest starts with a namespace definition!"
  type        = string
  default     = null
}