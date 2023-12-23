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

resource "kubectl_manifest" "this" {
  for_each = toset(fileset("${path.module}/manifests", "*.yaml"))

  yaml_body = templatefile("${path.module}/manifests/${each.value}", {
    awsAccountId = data.aws_caller_identity.this.account_id
    awsRegion    = data.aws_region.this.name
    clusterName  = var.cluster_name
  })
}
