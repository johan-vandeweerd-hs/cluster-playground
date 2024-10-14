variable "git_url" {
  description = "The Git URL used in the Argocd application manifest"
  type        = string
}

variable "git_revision" {
  description = "The Git revision used in the Argocd application manifest"
  type        = string
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster"
  type        = string
}

variable "cluster_oidc_provider" {
  description = "The name of the OIDC provider noof the Kubernetes cluster"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC provider of the Kubernetes cluster"
  type        = string
}
