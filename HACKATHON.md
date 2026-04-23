# Observability Hackathon

## Overview

This hackathon explored zero-code instrumentation using eBPF-based observability tools in Kubernetes.

## Infrastructure

The sandbox EKS cluster includes:

- **Networking**: VPC, load balancer, DNS records
- **Containerization**: EKS
- **Cluster tools**: Traefik, CertManager, ArgoCD, ExternalSecrets, OpenTelemetry Operator
- **Observability stack**: Prometheus workspace, Grafana
- **Messaging**: Kafka cluster (MSK)

## Test Applications

Three Go microservices ([source](https://github.hootops.com/hackathon/cluster-playground/tree/obi/images))
were built to exercise the instrumentation:

- **hello-service** -- HTTP server exposing `/hello?name=<name>`. Calls `message-service` to generate a greeting and
  simultaneously publishes it to a Kafka topic.
- **message-service** -- Returns a randomized `<hello>, <name>` greeting using one of 10 translations of "hello".
- **audit-service** -- Kafka consumer that logs each greeting to the terminal.

## Instrumentation Approaches

### Attempt 1: OpenTelemetry Operator sidecar

The OpenTelemetry Operator injects a per-pod sidecar that attaches eBPF uprobes to the Go process. This failed on our
EKS cluster because Bottlerocket's kernel lockdown blocks `bpf_probe_write_user`, which the sidecar needs for trace
context propagation ([relevant issue](https://github.com/open-telemetry/opentelemetry-go-instrumentation/issues/290)).

### Attempt 2: OBI (OpenTelemetry eBPF Instrumentation)

[OBI](https://opentelemetry.io/docs/zero-code/obi/) runs as a privileged DaemonSet and instruments applications at the
network protocol level rather than attaching to individual processes. It does not require `bpf_probe_write_user` (
context propagation is disabled by default), so it works on Bottlerocket.

OBI is currently running in the cluster and
generating [RED metrics](https://opentelemetry.io/docs/zero-code/obi/metrics/) that are scraped by Prometheus and are
available in Grafana.

## Try It Out

### Generate metrics

Visit [https://hello.johan.hackathon.hootops.com/hello?name=Marin](https://hello.johan.hackathon.hootops.com/hello?name=Marin)
a few times. Metrics are scraped every ~30 seconds.

### View metrics in Grafana

1. Log into [AWS Identity Center](https://d-9067b5f06b.awsapps.com/start/#/) (check your email for account setup
   instructions)
2. Go to the **Applications** tab and click **Amazon Grafana-johan**
3. Open the **Explore** page from the left navigation to query the available metrics

### Explore the cluster

The EKS cluster is accessible via ArgoCD (listed in AWS Identity Center applications) or `kubectl`:

```shell
vaultlogin
hs-iam-tool sync user-sandbox-admin
aws --profile user-sandbox-admin --region eu-west-1 eks update-kubeconfig --name johan --alias obi
kubectl config use-context obi
```
