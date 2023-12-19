module "eks" {
  source = "registry.terraform.io/terraform-aws-modules/eks/aws"

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
    role_name            = "${module.eks.cluster_name}-karpenter"
    role_name_use_prefix = false
    role_description     = "TF: IAM Role used by Karptener for IRSA."
    role_policies        = {}

    policy_name            = "${module.eks.cluster_name}-karpenter"
    policy_name_use_prefix = false
    policy_description     = "TF: Policy used by Karpenter role."
  }
  karpenter_node = {
    create_iam_role              = true
    iam_role_name                = "${module.eks.cluster_name}-karpenter-node"
    iam_role_use_name_prefix     = false
    iam_role_description         = "TF: IAM role used by Karpenter managed nodes."
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  enable_argocd = true
  argocd        = {
    values = [file("${path.module}/extras/argocd-values.yaml")]
  }

  enable_aws_load_balancer_controller = false
  aws_load_balancer_controller        = {}

  enable_cert_manager = true
  cert_manager        = {}

  enable_external_dns = false
  external_dns        = {}

  enable_external_secrets = true
  external_secrets        = {
    namespace            = "external-secrets"
    service_account_name = "external-secrets"

    create_role          = true
    role_name            = "${module.eks.cluster_name}-external-secrets"
    role_name_use_prefix = false
    role_description     = "TF: IAM role used by External Secrets for IRSA."

    policy_name             = "no-op"
    policy_name_use_prefix  = false
    policy_description      = "TF: IAM policy for External Secrets in the ${module.eks.cluster_name} cluster."
    source_policy_documents = [data.aws_iam_policy_document.no_op.json]
  }
  external_secrets_ssm_parameter_arns   = []
  external_secrets_secrets_manager_arns = []
  external_secrets_kms_key_arns         = []

  enable_metrics_server = true
  metrics_server        = {
    create_namespace = true
    namespace        = "metrics-server"
  }

  depends_on = [
    module.eks.fargate_profiles
  ]
}

data "aws_iam_policy_document" "no_op" {
  statement {
    effect    = "Allow"
    actions   = ["none:null"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "argocd" {
  name               = "${module.eks.cluster_name}-argocd"
  description        = "TF: IAM role assumed by External Secrets to get the secrets of Argocd."
  assume_role_policy = data.aws_iam_policy_document.argocd_assume.json

  inline_policy {
    name   = "read-secrets-manager"
    policy = data.aws_iam_policy_document.argocd_secrets_manager.json
  }
}

data "aws_iam_policy_document" "argocd_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [module.eks_blueprints_addons.external_secrets.iam_role_arn]
    }
  }
}

data "aws_iam_policy_document" "argocd_secrets_manager" {
  statement {
    effect  = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-west-1:${data.aws_caller_identity.this.account_id}:secret:${module.eks.cluster_name}/argocd/*"
    ]
  }
}

resource "kubectl_manifest" "this" {
  for_each = toset(fileset("${path.module}/extras/manifests", "**/*"))

  yaml_body = templatefile("${path.module}/extras/manifests/${each.value}", {
    awsAccountId = data.aws_caller_identity.this.account_id
    clusterName  = module.eks.cluster_name
    defaultTags  = data.aws_default_tags.this.tags
  })

  depends_on = [module.eks_blueprints_addons]
}
