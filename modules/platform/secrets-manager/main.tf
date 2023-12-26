locals {
  module_name = basename(abspath(path.module))
}

resource "kubectl_manifest" "application" {
  yaml_body = templatefile("${path.module}/chart/application.yaml", {
    name            = local.module_name
    namespace       = local.module_name
    gitUrl          = var.git_url
    revision        = var.git_revision
    helmParameters = {
      awsRegion   = data.aws_region.this.name
      clusterName = var.cluster_name
      "external-secrets.serviceAccount.annotations.'eks.amazonaws.com/role-arn'" = module.iam_role.iam_role_arn
    }
  })
}

module "iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name        = "${var.cluster_name}-external-secrets"
  role_description = "TF: IAM role used by External Secrets for IRSA."

  oidc_providers = {
    (var.cluster_name) = {
      provider                   = var.cluster_oidc_provider
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }
}
