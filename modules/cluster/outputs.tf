output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}
#
#output "karpenter_queue_name" {
#  description = "The SQS queue name used to notify Karpenter of spot instance being terminated"
#  value       = module.karpenter.queue_name
#}
#
#output "karpenter_irsa_arn" {
#  description = "The ARN of the IRSA role name of Karpenter"
#  value       = module.karpenter.irsa_arn
#}