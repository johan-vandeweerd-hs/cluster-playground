variable "project_name" {
  description = "Name to use for the VPC, EKS cluster, etc and to use as prefix to name resources."
  type        = string
}

variable "git_url" {
  description = "The Git URL used in the Argpcd application manifests."
  type        = string
}

variable "git_revision" {
  description = "The Git revision used in the Argpcd application manifests."
  type        = string
  default     = null
}
