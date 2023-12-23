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

  cluster_addons = {
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

  fargate_profiles = {
    karpenter = {
      iam_role_name            = "${var.cluster_name}-fargate-karpenter"
      iam_role_use_name_prefix = false
      iam_role_description     = "TF: IAM role used by Fargate for karpenter profile."
      selectors                = [
        { namespace = "karpenter" }
      ]
    }
    kube-system = {
      iam_role_name            = "${var.cluster_name}-fargate-kube-system"
      iam_role_use_name_prefix = false
      iam_role_description     = "TF: IAM role used by Fargate for kube-system profile."
      selectors                = [
        {
          namespace = "kube-system"
          labels    = {
            "eks.amazonaws.com/component" = "coredns"
            "k8s-app"                     = "kube-dns"
          }
        }
      ]
    }
  }
}

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

module "argocd" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_version   = module.eks.cluster_version
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_argocd = true
  argocd        = {
    values = [file("${path.module}/manifests/argocd-helm-values.yaml")]
  }
}

resource "kubectl_manifest" "argocd" {
  for_each = toset(fileset("${path.module}/manifests/argocd", "*.yaml"))

  yaml_body = templatefile("${path.module}/manifests/argocd/${each.value}", {
  })

  depends_on = [
    module.argocd
  ]
}
