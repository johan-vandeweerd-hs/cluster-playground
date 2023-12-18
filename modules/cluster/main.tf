module "eks" {
  source = "registry.terraform.io/terraform-aws-modules/eks/aws"

  cluster_name    = var.name
  cluster_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.public_subnet_ids

  cluster_endpoint_public_access = false

  cloudwatch_log_group_retention_in_days = 7

  cluster_security_group_name            = "${var.name}-cluster"
  cluster_security_group_use_name_prefix = false
  cluster_security_group_description     = "TF: Security group used by the ${var.name} cluster"

  node_security_group_name            = "${var.name}-node"
  node_security_group_use_name_prefix = false
  node_security_group_description     = "TF: Security group used by the nodes of the ${var.name} cluster"
  node_security_group_tags            = {
    "karpenter.sh/discovery" = var.name
  }

  iam_role_name            = "${var.name}-cluster"
  iam_role_use_name_prefix = false
  iam_role_description     = "TF: IAM role used by the ${var.name} cluster"

  cluster_encryption_policy_name            = "${var.name}-encryption"
  cluster_encryption_policy_use_name_prefix = false
  cluster_encryption_policy_description     = "TF: IAM policy used by the ${var.name} cluster for encryption"

  manage_aws_auth_configmap = true
  aws_auth_roles            = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:role/${var.name}-karpenter-node"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]

  fargate_profiles = {
    karpenter = {
      iam_role_name            = "${var.name}-fargate-karpenter"
      iam_role_use_name_prefix = false
      iam_role_description     = "TF: IAM role used by Fargate for karpenter profile"
      selectors                = [
        { namespace = "karpenter" }
      ]
    }
    kube-system = {
      iam_role_name            = "${var.name}-fargate-kube-system"
      iam_role_use_name_prefix = false
      iam_role_description     = "TF: IAM role used by Fargate for kube-system profile"
      selectors                = [
        { namespace = "kube-system" }
      ]
    }
  }
}

resource "aws_iam_service_linked_role" "spot" {
  count = length(data.aws_iam_roles.spot.names) > 0 ? 0 : 1

  aws_service_name = "spot.amazonaws.com"
}

module "eks_blueprints_addons" {
  source = "registry.terraform.io/aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
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
    adot = {
      most_recent = true
    }
    coredns = {
      most_recent          = true
      configuration_values = jsonencode({
        computeType = "Fargate"
        resources   = {
          requests = {
            cpu    = "0.25"
            memory = "256M"
          }
          limits = {
            cpu    = "0.25"
            memory = "256M"
          }
        }
      })
    }
  }

  enable_karpenter = true
  karpenter        = {
    create_role          = true
    role_name            = "${var.name}-karpenter"
    role_name_use_prefix = false
    role_description     = "TF: IAM Role used by Karptener for IRSA"
    role_policies        = {}

    policy_name            = "${var.name}-karpenter"
    policy_name_use_prefix = false
    policy_description     = "TF: Policy used by Karpenter role"
  }
  karpenter_node = {
    create_iam_role              = true
    iam_role_name                = "${var.name}-karpenter-node"
    iam_role_use_name_prefix     = false
    iam_role_description         = "TF: IAM role used by Karpenter managed nodes"
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  enable_argocd = false
  argocd        = {}

  enable_aws_load_balancer_controller = false
  aws_load_balancer_controller        = {}

  enable_cert_manager = true
  cert_manager        = {}

  enable_external_dns = false
  external_dns        = {}

  enable_external_secrets = false
  external_secrets        = {}

  enable_metrics_server = true
  metrics_server        = {
    create_namespace = true
    namespace        = "metrics-server"
  }
}

resource "time_sleep" "wait_for_eks_blueprints_addons" {
  depends_on = [module.eks_blueprints_addons]

  create_duration = "120s"
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = templatefile("${path.module}/manifests/karpenter/node-class.yaml", {
    "clusterName" = var.name,
    "defaultTags" = data.aws_default_tags.this.tags
  })

  depends_on = [time_sleep.wait_for_eks_blueprints_addons]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = templatefile("${path.module}/manifests/karpenter/node-pool.yaml", { CLUSTER_NAME = var.name })

  depends_on = [time_sleep.wait_for_eks_blueprints_addons]
}

#resource "kubectl_manifest" "adot_collector" {
#  yaml_body = templatefile("${path.module}/manifests/adot_collector.yaml", { CLUSTER_NAME = var.name })
#
#  depends_on = [time_sleep.wait_for_eks_blueprints_addons]
#}
