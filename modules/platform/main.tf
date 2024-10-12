module "cert_manager" {
  source = "./cert-manager"

  git_url      = var.git_url
  git_revision = var.git_revision

  cluster_name                       = var.cluster_name
  cluster_oidc_provider              = var.cluster_oidc_provider
  cluster_oidc_provider_arn          = var.cluster_oidc_provider_arn
}

module "external_secrets" {
  source = "./external-secrets"

  git_url      = var.git_url
  git_revision = var.git_revision

  cluster_name                       = var.cluster_name
  cluster_oidc_provider              = var.cluster_oidc_provider
  cluster_oidc_provider_arn          = var.cluster_oidc_provider_arn
}

module "ingress" {
  source = "./ingress"

  git_url      = var.git_url
  git_revision = var.git_revision

  cluster_name                       = var.cluster_name
  cluster_oidc_provider              = var.cluster_oidc_provider
  cluster_oidc_provider_arn          = var.cluster_oidc_provider_arn
}

module "open_telemetry" {
  source = "./open-telemetry"

  git_url      = var.git_url
  git_revision = var.git_revision

  cluster_name                       = var.cluster_name
  cluster_oidc_provider              = var.cluster_oidc_provider
  cluster_oidc_provider_arn          = var.cluster_oidc_provider_arn
}
