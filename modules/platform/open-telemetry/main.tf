locals {
  moduleName = basename(abspath(path.module))
}

resource "kubectl_manifest" "application" {
  yaml_body = templatefile("${path.module}/chart/application.yaml", {
    name           = local.moduleName
    namespace      = local.moduleName
    gitUrl         = var.git_url
    revision       = var.git_revision
    helmParameters = {
      roleArn = aws_iam_role.open_telemetry.arn
    }
  })
}

resource "aws_iam_role" "open_telemetry" {
  name               = "${var.cluster_name}-open-telemetry"
  assume_role_policy = data.aws_iam_policy_document.open_telemetry_assume.json

  inline_policy {
    name   = "cloudwatch-read-only"
    policy = data.aws_iam_policy_document.cloudwatch_read_only.json
  }
}

data "aws_iam_policy_document" "open_telemetry_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      identifiers = [var.cluster_oidc_provider_arn]
      type        = "Federated"
    }
    condition {
      test     = "StringEquals"
      variable = "${var.cluster_oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.cluster_oidc_provider}:sub"
      values   = ["system:serviceaccount:open-telemetry:open-telemetry"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect  = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:GetLogGroupFields",
      "logs:GetLogRecord",
    ]
    resources = ["*"]
  }
}
