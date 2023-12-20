variable "name" {
  description = "Name used to identify resources."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to create resources in."
  type = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "List of AZs that are used in the VPC (eg eu-west-1a)."
  type        = list(string)
}

variable "private_subnets" {
  description = "The CIDR blocks used for the private subnets."
  type        = list(string)
}

variable "public_subnets" {
  description = "The CIDR blocks used for the public subnets."
  type        = list(string)
}

