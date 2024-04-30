data "aws_iam_roles" "spot" {
  name_regex = "AWSServiceRoleForEC2Spot"
}
