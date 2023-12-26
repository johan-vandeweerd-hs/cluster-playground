# We wait for the EKS cluster to be up and the Karpenter fargate profile to be
# created. If we don't, the Karpenter node-class and node-pool can't be created
# because the Karpenter admission controller is not available yet.
module "karpenter" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_version   = module.eks.cluster_version
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_karpenter = true
  karpenter        = {
    create_role          = true
    role_name            = "${var.cluster_name}-karpenter"
    role_name_use_prefix = false
    role_description     = "TF: IAM Role used by Karptener for IRSA."
    role_policies        = {}

    policy_name            = "${var.cluster_name}-karpenter"
    policy_name_use_prefix = false
    policy_description     = "TF: Policy used by Karpenter role."
  }
  karpenter_node = {
    create_iam_role              = true
    iam_role_name                = "${var.cluster_name}-karpenter-node"
    iam_role_use_name_prefix     = false
    iam_role_description         = "TF: IAM role used by Karpenter managed nodes."
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  depends_on = [
    module.eks.fargate_profiles
  ]
}

# Wait for Karpenter to be up and the admission controller to be ready
resource "time_sleep" "wait_for_karpenter" {
  create_duration  = "60s"
  destroy_duration = "30s"

  depends_on = [
    module.karpenter
  ]
}

resource "kubectl_manifest" "karpenter" {
  for_each = toset(fileset("${path.module}/karpenter/manifests", "*.yaml"))

  yaml_body = templatefile("${path.module}/karpenter/manifests/${each.value}", {
    clusterName = var.cluster_name
    defaultTags = data.aws_default_tags.this.tags
  })

  depends_on = [
    time_sleep.wait_for_karpenter
  ]
}

resource "aws_iam_service_linked_role" "spot" {
  count = length(data.aws_iam_roles.spot.names) > 0 ? 0 : 1

  aws_service_name = "spot.amazonaws.com"
}
