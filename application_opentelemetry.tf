resource "kubectl_manifest" "argocd_application_opentelemetrycollectors" {
  yaml_body = templatefile("${path.module}/applications/open-telemetry-collectors/argocd-application.yaml", {
    valuesObject = {
      aws = {
        region = data.aws_region.this.id
      }
      prometheus = {
        endpoint = module.prometheus.workspace_prometheus_endpoint
      }
    }
    clusterArn = module.eks.cluster_arn
  })

  depends_on = [aws_eks_capability.argocd]
}

module "open_telemetry_iam_role" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "${var.project_name}-open-telemetry"
  use_name_prefix = false
  description     = "TF: IAM role to be assumed by External Secrets Operator to send metrics to AMP."

  trust_policy_conditions = [
    {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = [module.eks.cluster_arn]
    }
  ]

  associations = {
    open-telemetry-metrics-collector = {
      cluster_name    = module.eks.cluster_name
      namespace       = "open-telemetry"
      service_account = "open-telemetry-metrics-collector"
    }
  }

  attach_custom_policy      = true
  custom_policy_description = "TF: IAM policy for OpenTelemetry collectors to send metrics to AMP."
  policy_statements = [
    {
      sid       = "AllowPrometheusRemoteWrite"
      effect    = "Allow"
      actions   = ["aps:RemoteWrite"]
      resources = [module.prometheus.workspace_arn]
    },
  ]
}
