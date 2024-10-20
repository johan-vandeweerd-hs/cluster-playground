module "httpbin" {
  source = "./httpbin"

  git_url      = var.git_url
  git_revision = var.git_revision
  project_name = var.project_name
}

module "bucket_lister" {
  source = "./bucket-lister"

  git_url      = var.git_url
  git_revision = var.git_revision
  project_name = var.project_name
}