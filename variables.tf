variable "project_name" {
  description = "Name to use for the VPC, EKS cluster, etc and to use as prefix to name resources."
  type = string
  default = ""
}

variable "git_url" {
  description = "The Git URL used in the Argpcd application manifests."
  type        = string
}

variable "contributor" {
  description = "The name of the person contributing to this and who runs this infrastructure."
  type        = string
}
