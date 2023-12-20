module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = var.cluster_name
  cluster_endpoint  = var.cluster_endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = var.cluster_oidc_provider_arn

  enable_argocd = true
  argocd        = {
    values = [file("${path.module}/helm-values.yaml")]
  }
}

resource "aws_iam_role" "argocd" {
  name               = "${var.cluster_name}-argocd"
  description        = "TF: IAM role assumed by External Secrets to get the secrets of Argocd."
  assume_role_policy = data.aws_iam_policy_document.argocd_assume.json

  inline_policy {
    name   = "read-secrets-manager"
    policy = data.aws_iam_policy_document.argocd_secrets_manager.json
  }
}

data "aws_iam_policy_document" "argocd_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.external_secrets_iam_role_arn]
    }
  }
}

data "aws_iam_policy_document" "argocd_secrets_manager" {
  statement {
    effect  = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:secret:${var.cluster_name}/argocd/*"
    ]
  }
}

resource "time_sleep" "wait_for_argocd" {
  create_duration = "30s"

  depends_on = [module.eks_blueprints_addons]
}

resource "kubectl_manifest" "this" {
  for_each = toset(fileset("${path.module}/manifests", "*.yaml"))

  yaml_body = templatefile("${path.module}/manifests/${each.value}", {
    awsAccountId = data.aws_caller_identity.this.account_id
    awsRegion    = data.aws_region.this.name
    clusterName  = var.cluster_name
  })

  depends_on = [
    time_sleep.wait_for_argocd
  ]
}
