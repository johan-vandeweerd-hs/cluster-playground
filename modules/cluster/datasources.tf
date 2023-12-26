data "aws_region" "this" {
}

data "aws_caller_identity" "this" {
}

data "aws_default_tags" "this" {
}

data "aws_iam_roles" "spot" {
  name_regex = "AWSServiceRoleForEC2Spot"
}
