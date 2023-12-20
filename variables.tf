variable "aws_region" {
  description = "The AWS region to create resources in."
  type = string
}

variable "git_url" {
  description = "The Git URL used in the Argpcd application manifests."
  type        = string
}

variable "contributor" {
  description = "The name of the person contributing to this and who runs this infrastructure."
  type        = string
}
