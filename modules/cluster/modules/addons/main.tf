module "eks_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = var.project_name
  cluster_version   = var.kubernetes_version
  cluster_endpoint  = var.kubernetes_endpoint
  oidc_provider_arn = var.kubernetes_oidc_provider_arn

  eks_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    coredns = {
      most_recent          = true
      configuration_values = jsonencode(yamldecode(file("${path.module}/coredns.yaml")))
    }
    aws-ebs-csi-driver = {
      most_recent          = true
      configuration_values = jsonencode(yamldecode(file("${path.module}/aws-ebs-csi-driver.yaml")))
    }
  }
}

# AWS EBS CSI Driver
module "iam_role_aws_ebs_csi_driver" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name            = "${var.project_name}-aws-ebs-csi-driver"
  description     = "TF: IAM role used by AWS EBS CSI driver."
  use_name_prefix = "false"

  attach_aws_ebs_csi_policy = true

  associations = {
    "kube-system" = {
      cluster_name    = var.project_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }
}

# StorageClass
resource "kubernetes_manifest" "storage_class" {
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
      name = "ebs"
    }
    provisioner       = "ebs.csi.aws.com"
    volumeBindingMode = "WaitForFirstConsumer"
    allowedTopologies = [
      {
        matchLabelExpressions = [
          {
            key    = "topology.ebs.csi.aws.com/zone"
            values = ["${data.aws_region.this.name}a"]
          }
        ]
      }
    ]
  }
}
