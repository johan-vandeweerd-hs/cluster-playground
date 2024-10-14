resource "aws_eks_pod_identity_association" "default" {
  cluster_name    = var.cluster_name
  namespace       = "default"
  service_account = "pod-identity"
  role_arn        = aws_iam_role.pod_identity.arn
}

resource "aws_iam_role" "pod_identity" {
  name               = "${var.cluster_name}-pod-identity"
  description        = "TF: IAM role used by EKS to create pod identity associations"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "assume" {
  statement {
    sid    = "AllowEksAuthToAssumeRoleForPodIdentity"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role_policy" "pod_identity" {
  role   = aws_iam_role.pod_identity.name
  name   = "PodIdentity"
  policy = data.aws_iam_policy_document.pod_identity.json
}

data "aws_iam_policy_document" "pod_identity" {
  statement {
    sid    = "AllowCreatePodIdentityAssociations"
    effect = "Allow"
    actions = [
      "eks:ListPodIdentityAssociations",
      "eks:CreatePodIdentityAssociation",
    ]
    resources = [var.cluster_arn]
  }
  statement {
    sid    = "AllowDeleteUpdatePodIdentityAssociations"
    effect = "Allow"
    actions = [
      "eks:DeletePodIdentityAssociation",
      "eks:UpdatePodIdentityAssociation",
    ]
    resources = ["arn:${data.aws_partition.this.id}:eks:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:podidentityassociation/${var.cluster_name}/*"]
  }
  statement {
    sid    = "AllowPassAndGetRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "iam:GetRole",
    ]
    resources = ["*"]
  }
}

resource "kubectl_manifest" "service_account" {
  yaml_body = <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-identity
  namespace: default
EOF
}
