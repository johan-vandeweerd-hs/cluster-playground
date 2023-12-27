locals {
  module_name = basename(abspath(path.module))
}

resource "kubectl_manifest" "application" {
  yaml_body = templatefile("${path.module}/chart/application.yaml", {
    name           = local.module_name
    namespace      = local.module_name
    gitUrl         = var.git_url
    revision       = var.git_revision
    helmParameters = merge({for key, value in data.aws_default_tags.this.tags : "tags.${key}" => value}, {
      clusterName                                                                                  = var.cluster_name
      certificateArn                                                                               = module.acm.acm_certificate_arn
      "aws-load-balancer-controller.clusterName"                                                   = var.cluster_name
      "aws-load-balancer-controller.serviceAccount.annotations.eks\\\\.amazonaws\\\\.com/role-arn" = module.iam_role.iam_role_arn
      "aws-load-balancer-controller.vpcId"                                                         = data.aws_vpc.this.id
    })
  })
}

module "iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name        = "${var.cluster_name}-aws-load-balancer-controller"
  role_description = "TF: IAM role used by AWS Load Balancer controller for IRSA."

  oidc_providers = {
    (var.cluster_name) = {
      provider                   = var.cluster_oidc_provider
      provider_arn               = var.cluster_oidc_provider_arn
      namespace_service_accounts = ["aws-load-balancer-controller:aws-load-balancer-controller"]
    }
  }

  role_policy_arns = {
    "aws-load-balancer-controller" = aws_iam_policy.this.arn
  }
}

# IAM
resource "aws_iam_policy" "this" {
  name        = "aws-load-balancer-controller"
  description = "TF: IAM policy to allow read access for secrets of Argocd"

  policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    effect  = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "ec2:Vpc"
      values   = [
        "arn:aws:ec2:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:vpc/${data.aws_vpc.this.id}"
      ]
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags"
    ]
    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = [
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection"
    ]
    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = [
      "ec2:CreateSecurityGroup"
    ]
    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSecurityGroup"]
    }
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup"
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup"
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule"
    ]
    resources = ["*"]
  }
  statement {
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup"
    ]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:AddTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"
      values   = [
        "CreateTargetGroup",
        "CreateLoadBalancer"
      ]
    }
    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }
  statement {
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule"
    ]
    resources = ["*"]
  }
}

# DNS
resource "aws_route53_zone" "cluster_hackathon_hootops_com" {
  name    = "${var.cluster_name}.hackathon.hootops.com"
  comment = "TF: Subdomain for ${var.cluster_name} of hackathon.hootops.com."
}

resource "aws_route53_record" "hackathon_hootops" {
  zone_id = data.aws_route53_zone.hackathon.zone_id
  name    = var.cluster_name
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.cluster_hackathon_hootops_com.name_servers
}

# Certificate
module "acm" {
  source = "terraform-aws-modules/acm/aws"

  domain_name = "${var.cluster_name}.hackathon.hootops.com"
  zone_id     = aws_route53_zone.cluster_hackathon_hootops_com.zone_id

  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.cluster_name}.hackathon.hootops.com"
  ]

  wait_for_validation = true
}
