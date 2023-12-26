module "argocd" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_version   = module.eks.cluster_version
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_argocd = true
  argocd        = {
    values = [file("${path.module}/argocd/helm-values.yaml")]
  }
}

resource "kubectl_manifest" "argocd" {
  for_each = toset(fileset("${path.module}/argocd/manifests", "*.yaml"))

  yaml_body = templatefile("${path.module}/argocd/manifests/${each.value}", {
    awsRegion   = data.aws_region.this.name
    clusterName = var.cluster_name
    roleArn     = module.argocd_iam_role.iam_role_arn
    gitUrl      = var.git_url
  })
}

module "argocd_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name        = "${var.cluster_name}-argocd"
  role_description = "TF: IAM role used by job for creating secret with Github SSH key."

  oidc_providers = {
    (var.cluster_name) = {
      provider                   = module.eks.oidc_provider
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["argocd:argocd"]
    }
  }

  role_policy_arns = {
    "secrets-manager-argocd-read-only" = aws_iam_policy.secrets_manager_argocd_read_only.arn
  }
}

resource "aws_iam_policy" "secrets_manager_argocd_read_only" {
  name        = "secrets-manager-argocd-read-only"
  description = "TF: IAM policy to allow read access for secrets of Argocd"

  policy = data.aws_iam_policy_document.secrets_manager_argocd_read_only.json
}

data "aws_iam_policy_document" "secrets_manager_argocd_read_only" {
  statement {
    effect  = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:secret:${module.eks.cluster_name}/argocd/*"
    ]
  }
}
