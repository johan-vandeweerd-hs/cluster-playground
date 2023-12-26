variable "cluster_name" {
  description = "The name of the Kubernetes cluster."
  type        = string
}

variable "cluster_version" {
  description = "The version of Kubernetes to use."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to create the Kubernetes cluster in."
  type        = string
}

variable "private_subnet_ids" {
  description = "The list of IDs of the private subnets to use."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "The list of IDs of the public subnets to use."
  type        = list(string)
}

variable "git_url" {
  description = "The Git URL used in the Argpcd application manifests."
  type        = string
}
