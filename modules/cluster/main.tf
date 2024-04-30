module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.public_subnet_ids

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  cloudwatch_log_group_retention_in_days = 7

  create_cluster_security_group = false
  create_node_security_group    = false

  iam_role_name            = "${var.cluster_name}-cluster"
  iam_role_use_name_prefix = false
  iam_role_description     = "TF: IAM role used by the ${var.cluster_name} cluster control plane."

  cluster_encryption_policy_name            = "${var.cluster_name}-encryption"
  cluster_encryption_policy_use_name_prefix = false
  cluster_encryption_policy_description     = "TF: IAM policy used by the ${var.cluster_name} cluster for encryption."
}

module "karpenter" {
  source = "./modules/karpenter"

  cluster_name              = module.eks.cluster_name
  cluster_endpoint          = module.eks.cluster_endpoint
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn

  private_subnet_ids = var.private_subnet_ids
}

module "argocd" {
  source = "./modules/argocd"

  cluster_name              = module.eks.cluster_name
  cluster_oidc_provider     = module.eks.oidc_provider
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn

  git_url = var.git_url

  depends_on = [
    module.karpenter
  ]
}

module "addons" {
  source = "./modules/addons"

  cluster_name              = module.eks.cluster_name
  cluster_version           = module.eks.cluster_version
  cluster_endpoint          = module.eks.cluster_endpoint
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn

  depends_on = [
    module.karpenter
  ]
}
