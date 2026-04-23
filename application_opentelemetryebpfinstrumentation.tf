resource "kubectl_manifest" "argocd_application_opentelemetryebpfinstrumentation" {
  yaml_body = templatefile("${path.module}/applications/open-telemetry-ebpf-instrumentation/argocd-application.yaml", {
    clusterArn = module.eks.cluster_arn
    valuesObject = {
      config = {
        data = {
          discovery = {
            instrument = [
              { k8s_namespace = "default" }
            ]
          }
          prometheus_export = {
            port = 9090
            path = "/metrics"
          }
          otel_traces_export = {
            endpoint = ""
          }
          otel_metrics_export = {
            endpoint = ""
          }
          attributes = {
            kubernetes = {
              enable = "true"
            }
          }
        }
      }
      service = {
        enabled = true
      }
      env = {
        OTEL_EBPF_KUBE_CLUSTER_NAME = module.eks.cluster_name
      }
      podAnnotations = {
        "prometheus.io/scrape" = "true"
      }
    }
  })

  depends_on = [aws_eks_capability.argocd]
}
