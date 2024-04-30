module "aws_load_balancer_controller" {
  source = "./aws-load-balancer-controller"

  git_url      = var.git_url
  git_revision = var.git_revision

  cluster_name                       = var.cluster_name
  cluster_endpoint                   = var.cluster_endpoint
  cluster_certificate_authority_data = var.cluster_certificate_authority_data
  cluster_oidc_provider              = var.cluster_oidc_provider
  cluster_oidc_provider_arn          = var.cluster_oidc_provider_arn
}

module "cert_manager" {
  source = "./cert-manager"

  git_url      = var.git_url
  git_revision = var.git_revision

  cluster_name                       = var.cluster_name
  cluster_endpoint                   = var.cluster_endpoint
  cluster_certificate_authority_data = var.cluster_certificate_authority_data
  cluster_oidc_provider              = var.cluster_oidc_provider
  cluster_oidc_provider_arn          = var.cluster_oidc_provider_arn
}

module "external_dns" {
  source = "./external-dns"

  git_url      = var.git_url
  git_revision = var.git_revision

  cluster_name                       = var.cluster_name
  cluster_endpoint                   = var.cluster_endpoint
  cluster_certificate_authority_data = var.cluster_certificate_authority_data
  cluster_oidc_provider              = var.cluster_oidc_provider
  cluster_oidc_provider_arn          = var.cluster_oidc_provider_arn
}

module "external_secrets" {
  source = "./external-secrets"

  git_url      = var.git_url
  git_revision = var.git_revision

  cluster_name                       = var.cluster_name
  cluster_endpoint                   = var.cluster_endpoint
  cluster_certificate_authority_data = var.cluster_certificate_authority_data
  cluster_oidc_provider              = var.cluster_oidc_provider
  cluster_oidc_provider_arn          = var.cluster_oidc_provider_arn
}

module "open_telemetry" {
  source = "./open-telemetry"

  git_url      = var.git_url
  git_revision = var.git_revision

  cluster_name                       = var.cluster_name
  cluster_endpoint                   = var.cluster_endpoint
  cluster_certificate_authority_data = var.cluster_certificate_authority_data
  cluster_oidc_provider              = var.cluster_oidc_provider
  cluster_oidc_provider_arn          = var.cluster_oidc_provider_arn
}
