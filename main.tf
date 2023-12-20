locals {
  name            = "cluster-playground-${var.contributor}"
  vpc_cidr        = "10.0.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "network" {
  source = "./modules/network"

  aws_region = var.aws_region

  name            = local.name
  vpc_cidr        = local.vpc_cidr
  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
}

module "cluster" {
  source = "./modules/cluster"

  aws_region = var.aws_region

  cluster_version = "1.28"

  name               = local.name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids
}

module "open_telemetry" {
  source = "./modules/platform/open-telemetry"

  git_url      = var.git_url
  git_revision = var.contributor

  cluster_name                       = module.cluster.cluster_name
  cluster_endpoint                   = module.cluster.cluster_endpoint
  cluster_certificate_authority_data = module.cluster.cluster_certificate_authority_data
  cluster_oidc_provider              = module.cluster.cluster_oidc_provider
  cluster_oidc_provider_arn          = module.cluster.cluster_oidc_provider_arn
}
