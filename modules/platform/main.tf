module "aws_controller_kubernetes" {
  source = "./aws-controller-kubernetes"

  project_name = var.project_name

  git_url      = var.git_url
  git_revision = var.git_revision

  kubernetes_oidc_provider     = var.kubernetes_oidc_provider
  kubernetes_oidc_provider_arn = var.kubernetes_oidc_provider_arn
}

module "cert_manager" {
  source = "./cert-manager"

  project_name = var.project_name

  git_url      = var.git_url
  git_revision = var.git_revision

  kubernetes_oidc_provider     = var.kubernetes_oidc_provider
  kubernetes_oidc_provider_arn = var.kubernetes_oidc_provider_arn

  hosted_zone = var.hosted_zone
}

module "external_secrets" {
  source = "./external-secrets"

  project_name = var.project_name

  git_url      = var.git_url
  git_revision = var.git_revision

  kubernetes_oidc_provider     = var.kubernetes_oidc_provider
  kubernetes_oidc_provider_arn = var.kubernetes_oidc_provider_arn
}

module "ingress" {
  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  source = "./ingress"

  project_name = var.project_name

  git_url      = var.git_url
  git_revision = var.git_revision

  kubernetes_oidc_provider     = var.kubernetes_oidc_provider
  kubernetes_oidc_provider_arn = var.kubernetes_oidc_provider_arn

  hosted_zone = var.hosted_zone
}
