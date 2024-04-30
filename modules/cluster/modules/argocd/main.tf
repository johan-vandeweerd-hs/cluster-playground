resource "helm_release" "this" {
  name  = "argocd"
  chart = "${path.module}/chart"

  dependency_update = true

  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "valuesChecksum"
    value = filemd5("${path.module}/chart/values.yaml")
  }

  set {
    name  = "templatesChecksum"
    value = md5(join("\n", [
      for filename in fileset(path.module, "chart/templates/**") :file("${path.module}/${filename}")
    ]))
  }

  set {
    name  = "argo-cd.server.ingress.hostname"
    value = "argocd.${var.cluster_name}.hackathon.hootops.com"
  }

  set {
    name  = "cluster.name"
    value = var.cluster_name
  }

  set {
    name  = "role.arn"
    value = module.iam_role.iam_role_arn
  }

  set {
    name  = "aws.region"
    value = data.aws_region.this.name
  }

  set {
    name  = "git.url"
    value = var.git_url
  }
}

module "iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name        = "${var.cluster_name}-argocd"
  role_description = "TF: IAM role used by job for creating secret with Github SSH key."

  oidc_providers = {
    (var.cluster_name) = {
      provider                   = var.cluster_oidc_provider
      provider_arn               = var.cluster_oidc_provider_arn
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
      "arn:aws:secretsmanager:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:secret:${var.cluster_name}/argocd/*"
    ]
  }
}
