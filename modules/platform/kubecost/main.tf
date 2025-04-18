# ArgoCD applications
resource "kubectl_manifest" "application_kubecost" {
  yaml_body = templatefile("${path.module}/chart/application.yaml", {
    name      = "kubecost"
    namespace = "kubecost"
    gitUrl    = var.git_url
    revision  = var.git_revision
    helmParameters = merge({ for key, value in data.aws_default_tags.this.tags : "tags.${key}" => value }, {
      kubecost.global.amp.enabled                  = true
      kubecost.global.amp.prometheusServerEndpoint = "http://localhost:8005/workspaces/${aws_prometheus_workspace.this.id}"
      kubecost.global.amp.remoteWriteService       = "https://aps-workspaces.${data.aws_region.this.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.this.id}/api/v1/remote_write"
      kubecost.global.sigv4.region                 = "${data.aws_region.this.name}"
      kubecost.sigV4Proxy.region                   = "${data.aws_region.this.name}"
      kubecost.sigV4Proxy.host                     = "aps-workspaces.${data.aws_region.this.name}.amazonaws.com"
    })
  })
}

# Prometheus
resource "aws_prometheus_workspace" "this" {
  alias = var.project_name
}

module "iam_role_kubecost_cost_analyzer" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "${var.project_name}-kubecost-cost-analyzer"
  description     = "TF: IAM role used by Kubecost cost analyzer."
  use_name_prefix = "false"

  additional_policy_arns = {
    AmpQueryAccess = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
    AmpWriteAccess = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  }
}

module "iam_role_kubecost_prometheus_server" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "${var.project_name}-kubecost-prometheus-server"
  description     = "TF: IAM role used by Kubecost Prometheus server."
  use_name_prefix = "false"

  additional_policy_arns = {
    AmpQueryAccess = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
    AmpWriteAccess = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  }
}
