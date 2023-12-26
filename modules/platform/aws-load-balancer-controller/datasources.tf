data "aws_region" "this" {
}

data "aws_caller_identity" "this" {
}

data "aws_vpc" "this" {
  filter {
    name = "tags:Name"
    values = [var.cluster_name]
  }
}
