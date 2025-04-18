locals {
  module_name = basename(abspath(path.module))
}

# ArgoCD application
resource "kubectl_manifest" "application_kubecost" {
  yaml_body = templatefile("${path.module}/chart/application.yaml", {
    name      = local.module_name
    namespace = local.module_name
    gitUrl    = var.git_url
    revision  = var.git_revision
    values = indent(8, yamlencode({
      cost-analyzer = {
        global = {
          amp = {
            enabled                  = true
            prometheusServerEndpoint = "http://localhost:8005/workspaces/${aws_prometheus_workspace.this.id}"
            remoteWriteService       = "https://aps-workspaces.${data.aws_region.this.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.this.id}/api/v1/remote_write"
          }
          sigv4 = {
            region = data.aws_region.this.name
          }
        }
        sigV4Proxy = {
          region = "${data.aws_region.this.name}"
          host   = "aps-workspaces.${data.aws_region.this.name}.amazonaws.com"
        }
      }
    }))
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

  associations = {
    "kube-system" = {
      cluster_name    = var.project_name
      namespace       = "kubecost"
      service_account = "kubecost-cost-analyzer"
    }
  }

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

  associations = {
    "kube-system" = {
      cluster_name    = var.project_name
      namespace       = "kubecost"
      service_account = "kubecost-prometheus-server"
    }
  }

  additional_policy_arns = {
    AmpQueryAccess = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
    AmpWriteAccess = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  }
}
