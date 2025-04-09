variable "aws_region" {
  description = "The AWS region to deploy the resources."
  type        = string
}

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
}

variable "git_private_ssh_key" {
  description = "The SSH key, as base64 encoded string, used by Argocd to sync with a private Git repository. Omit is using a public repository."
  type        = string
  default     = null
}

variable "hosted_zone" {
  description = "The hosted zone under which the project name is used as a subdomain for this project."
  type        = string
}

variable "letsencrypt_email" {
  description = "The email address used by Let's Encrypt."
  type        = string
}
