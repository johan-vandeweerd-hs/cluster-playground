module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = var.cluster_name
  cluster_endpoint  = var.cluster_endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = var.cluster_oidc_provider_arn

  enable_external_secrets = true
  external_secrets        = {
    namespace            = "external-secrets"
    service_account_name = "external-secrets"

    create_role          = true
    role_name            = "${var.cluster_name}-external-secrets"
    role_name_use_prefix = false
    role_description     = "TF: IAM role used by External Secrets for IRSA."

    policy_name             = "no-op"
    policy_name_use_prefix  = false
    policy_description      = "TF: IAM policy for External Secrets in the ${var.cluster_name} cluster."
    source_policy_documents = [data.aws_iam_policy_document.no_op.json]
  }
  external_secrets_ssm_parameter_arns   = []
  external_secrets_secrets_manager_arns = []
  external_secrets_kms_key_arns         = []
}

data "aws_iam_policy_document" "no_op" {
  statement {
    effect    = "Allow"
    actions   = ["none:null"]
    resources = ["*"]
  }
}
