locals {
  name         = var.project_name
  git_revision = coalesce(var.git_revision, var.project_name)
}

module "network" {
  source = "./modules/network"

  name = local.name
}

module "cluster" {
  source = "./modules/cluster"

  cluster_name    = local.name
  cluster_version = "1.31"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  git_url = var.git_url
}

module "platform" {
  source = "./modules/platform"

  git_url      = var.git_url
  git_revision = local.git_revision

  cluster_name                       = module.cluster.cluster_name
  cluster_oidc_provider              = module.cluster.cluster_oidc_provider
  cluster_oidc_provider_arn          = module.cluster.cluster_oidc_provider_arn
}
