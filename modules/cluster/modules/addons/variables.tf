variable "cluster_name" {
  description = "The name of the Kubernetes cluster."
  type        = string
}

variable "cluster_version" {
  description = "The version of Kubernetes to use."
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint of the Kubernetes cluster"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC provider of the Kubernetes cluster"
  type        = string
}

