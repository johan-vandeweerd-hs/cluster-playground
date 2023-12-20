module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.name
  cluster_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.public_subnet_ids

  cluster_endpoint_public_access = true

  cloudwatch_log_group_retention_in_days = 7

  create_cluster_primary_security_group_tags = true
  create_cluster_security_group              = false
  create_node_security_group                 = false
  cluster_tags                               = {
    "karpenter.sh/discovery" = var.name
  }

  iam_role_name            = "${var.name}-cluster"
  iam_role_use_name_prefix = false
  iam_role_description     = "TF: IAM role used by the ${var.name} cluster."

  cluster_encryption_policy_name            = "${var.name}-encryption"
  cluster_encryption_policy_use_name_prefix = false
  cluster_encryption_policy_description     = "TF: IAM policy used by the ${var.name} cluster for encryption."

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
      iam_role_name            = "${var.name}-fargate-karpenter"
      iam_role_use_name_prefix = false
      iam_role_description     = "TF: IAM role used by Fargate for karpenter profile."
      selectors                = [
        { namespace = "karpenter" }
      ]
    }
    kube-system = {
      iam_role_name            = "${var.name}-fargate-kube-system"
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
  source = "./modules/karpenter"

  cluster_name                       = module.eks.cluster_name
  cluster_version                    = module.eks.cluster_version
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  cluster_oidc_provider              = module.eks.oidc_provider
  cluster_oidc_provider_arn          = module.eks.oidc_provider_arn
}

module "external_secrets" {
  source = "./modules/external-secrets"

  cluster_name                       = module.eks.cluster_name
  cluster_version                    = module.eks.cluster_version
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  cluster_oidc_provider              = module.eks.oidc_provider
  cluster_oidc_provider_arn          = module.eks.oidc_provider_arn
}

resource "time_sleep" "wait_for_external_secrets" {
  create_duration = "60s"

  depends_on = [
    module.karpenter,
  ]
}

module "argocd" {
  source = "./modules/argocd"

  cluster_name                       = module.eks.cluster_name
  cluster_version                    = module.eks.cluster_version
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  cluster_oidc_provider              = module.eks.oidc_provider
  cluster_oidc_provider_arn          = module.eks.oidc_provider_arn

  external_secrets_iam_role_arn = module.external_secrets.iam_role_arn

  depends_on = [
    time_sleep.wait_for_external_secrets
  ]
}
