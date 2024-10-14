variable "git_url" {
  description = "The Git URL used in the Argocd application manifest"
  type        = string
}

variable "git_revision" {
  description = "The Git revision used in the Argocd application manifest"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}
