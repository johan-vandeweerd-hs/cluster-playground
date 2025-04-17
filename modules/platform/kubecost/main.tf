# ArgoCD applications
resource "kubectl_manifest" "application_kubecost" {
  yaml_body = templatefile("${path.module}/chart/application.yaml", {
    name      = "kubecost"
    namespace = "kubecost"
    gitUrl    = var.git_url
    revision  = var.git_revision
    helmParameters = merge({ for key, value in data.aws_default_tags.this.tags : "tags.${key}" => value }, {
    })
  })
}
