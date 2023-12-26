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
