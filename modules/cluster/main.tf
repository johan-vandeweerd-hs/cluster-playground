# EKS
module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.public_subnet_ids

  cluster_endpoint_public_access = true

  cloudwatch_log_group_retention_in_days = 7

  create_cluster_security_group = false
  create_node_security_group    = false

  iam_role_name            = "${var.cluster_name}-cluster"
  iam_role_use_name_prefix = false
  iam_role_description     = "TF: IAM role used by the ${var.cluster_name} cluster."

  cluster_encryption_policy_name            = "${var.cluster_name}-encryption"
  cluster_encryption_policy_use_name_prefix = false
  cluster_encryption_policy_description     = "TF: IAM policy used by the ${var.cluster_name} cluster for encryption."

  manage_aws_auth_configmap = true
  aws_auth_roles            = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${var.cluster_name}-karpenter-node"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]

  fargate_profiles = {
    karpenter = {
      iam_role_name            = "${var.cluster_name}-fargate-karpenter"
      iam_role_use_name_prefix = false
      iam_role_description     = "TF: IAM role used by Fargate for karpenter profile."
      selectors                = [
        { namespace = "karpenter" }
      ]
    }
  }
}

# Karpenter
#
# We wait for the EKS cluster to be up and the Karpenter fargate profile to be
# created. If we don't, the Karpenter node-class and node-pool can't be created
# because the adminssion controller of Karpenter is not available yet.
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

resource "aws_iam_service_linked_role" "spot" {
  count = length(data.aws_iam_roles.spot.names) > 0 ? 0 : 1

  aws_service_name = "spot.amazonaws.com"
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
  for_each = toset(fileset("${path.module}/manifests/karpenter", "*.yaml"))

  yaml_body = templatefile("${path.module}/manifests/karpenter/${each.value}", {
    clusterName = var.cluster_name
    defaultTags = data.aws_default_tags.this.tags
  })

  depends_on = [
    time_sleep.wait_for_karpenter
  ]
}

# EKS Addons and ArgoCD
#
# We wait for the NodePool and NodeClass to be created so Karpenter can spin up
# new EC2 nodes for Coredns and Argocd.
module "blueprint_addons" {
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
      configuration_values = jsonencode(yamldecode(file("${path.module}/manifests/coredns-values.yaml")))
    }
  }

  enable_argocd = true
  argocd        = {
    values = [file("${path.module}/manifests/helm-values.yaml")]
  }

  depends_on = [
    kubectl_manifest.karpenter
  ]
}

resource "kubectl_manifest" "argocd" {
  for_each = toset(fileset("${path.module}/manifests/argocd", "*.yaml"))

  yaml_body = templatefile("${path.module}/manifests/argocd/${each.value}", {
  })

  depends_on = [
    module.blueprint_addons
  ]
}
