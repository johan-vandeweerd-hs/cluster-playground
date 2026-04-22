resource "kubectl_manifest" "argocd_application_opentelemetryoperator" {
  yaml_body = templatefile("${path.module}/applications/open-telemetry-operator/argocd-application.yaml", {
    clusterArn = module.eks.cluster_arn
    valuesObject = {
      fullnameOverride     = "open-telemetry-operator"
      revisionHistoryLimit = 0
      admissionWebhooks = {
        autoGenerateCert = {
          enabled = false
        }
      }
      manager = {
        autoInstrumentation = {
          go = {
            enabled = true
          }
        }
      }
    }
  })

  depends_on = [aws_eks_capability.argocd]
}
