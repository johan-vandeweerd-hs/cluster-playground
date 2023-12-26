# We wait for the NodePool and NodeClass manifests to be applied so Karpenter
# can spin up new EC2 nodes for Coredns.
module "eks_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_version   = module.eks.cluster_version
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    coredns = {
      most_recent          = true
      configuration_values = jsonencode(yamldecode(file("${path.module}/coredns/configuration.yaml")))
    }
  }

  depends_on = [
    kubectl_manifest.karpenter
  ]
}
