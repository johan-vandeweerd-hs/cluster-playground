locals {
  module_name = basename(abspath(path.module))
}

# ArgoCD application
resource "argocd_application" "this" {
  metadata {
    name      = local.module_name
    namespace = "argocd"
  }
  spec {
    project = "default"
    source {
      repo_url        = var.git_url
      path            = "modules/platform/${local.module_name}/chart"
      target_revision = var.git_revision
      helm {
        values = yamlencode({
          kubecost = {
            global = {
              amp = {
                enabled                  = true
                prometheusServerEndpoint = "http://localhost:8005/workspaces/${aws_prometheus_workspace.this.id}"
                remoteWriteService       = "https://aps-workspaces.${data.aws_region.this.name}.amazonaws.com/workspaces/${aws_prometheus_workspace.this.id}/api/v1/remote_write"
              }
              sigv4 = {
                region = "${data.aws_region.this.name}"
              }
              sigV4Proxy = {
                region = "${data.aws_region.this.name}"
                host   = "aps-workspaces.${data.aws_region.this.name}.amazonaws.com"
              }
            }
          }
        })
      }
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = local.module_name
    }
    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }
      sync_options = ["CreateNamespace=true"]
    }
  }
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
