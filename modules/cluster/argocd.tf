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
  })

  depends_on = [
    module.argocd
  ]
}
