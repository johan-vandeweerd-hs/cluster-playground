# Cluster playground

Sample project to create an EKS cluster with Terraform and deploy applications using Argocd. All resources are created in their own VPC. The cluster also has the following services deployed:
- cert-manager for managing certificates
- external-secrets to sync secrets from AWS Secrets Manager to Kubernetes
- aws-controller-kubernetes with the EKS module to manage Pod Identity associations using Kubernetes manifests
- traefik as ingress controller
- aws-load-balancer-controller to manage target group binding using Kubernetes manifests

# Project structure

```
├── .github/       # Github Action workflows for building and pushing Docker images 
├── images/        # Source code and Dockerfile for applications. All is build using Github Actions
├── modules/ 
│   ├── cluster/   # Terraform module to create the EKS cluster
│   ├── network/   # Terraform module to create all VPC and network related resources
│   ├── platform/  # Terraform module to create all platform related resources like controllers for certificates, secrets, ingress, ...
│   └── product/   # Terraform module to create all application that use the cluster and the platform
├── scripts/       # Shell scripts to create and destroy the cluster 
├── main.tf        # Main Terraform file that uses all the modules
├── providers.tf   # All Terraform and provider configuration
└── variables.tf   # Define all the variables
```

# Setup

Create a `variables.auto.tfvars` file with the following content.

```hcl
# The AWS region to deploy your resources to eg us-east-1, eu-west-1
aws_region          = "<AWS_REGION>"
# A name for your project. This will be used as prefix and to tag all resources created by this module
project_name        = "<PROJECT_NAME>"
# The git repository that is added to Argocd to be able to sync applications 
git_url             = "git@github.com:<ORGANIZATION>/cluster-playground"
# The git branch Argocd will use to deploy applications
git_revision        = "<GIT_BRANCH>"
# The git private SSH key to access the git repository. You can add it in Github under repository settings - Deploy keys
git_private_ssh_key = "<BASE64_ENCODED_PRIVATE_SSH_KEY>"
# A new project hosted zone will be created (`<project_name>.<hosted_zone>`). An NS record will be created in the hosted zone `<hosted_zone>` to point to the project hosted zone.
hosted_zone         = "<AWS_ROUTE53_HOSTED_ZONE_NAME>"
# The email address that Let's Encrypt will use to send notifications. This is used by cert-manager to create certificates.
letsencrypt_email   = "<EMAIL_ADDRESS>"
```

Run the following command to bootstrap the cluster.

```shell
./scripts/create.sh
```

Once the cluster is up and running, you can update your kubeconfig:

```shell
aws eks update-kubeconfig --name <PROJECT_NAME> --alias <PROJECT_NAME> 
```

Once the cluster is up and running, and you want to make changes to the Terraform files, you can run the following command to apply the changes:

```shell
terraform apply
```

# Argocd

To open the Argocd UI, you can browse to `https://argocd.<PROJECT_NAME>.<hosted_zone>/` and login with username `admin` and the output of the following command as password: 

```shell
kubectl get secret -n argocd argocd-initial-admin-secret -ojson | jq -r '.data.password' | base64 -d 
```

In case the Argocd UI is not available on the above-mentioned URL, use port-forwarding instead: 

```shell
kubectl port-forward -n argocd service/argo-cd-argocd-server 8000:443
```

Browse to [https://localhost:8000](https://localhost:8000) and login with username `admin` and the output of the following command as password:

```shell
kubectl get secret -n argocd argocd-initial-admin-secret -ojson | jq -r '.data.password' | base64 -d 
```  

# Cleanup

When you are finished with the cluster, you can run the following command to destroy all resources:

```shell
./scripts/destroy.sh
```

If something goes wrong and you want to check if there are still some lingering resource, you can use the following command to list them:

```shell
export AWS_REGION="<AWS_REGION>"
export PROJECT_NAME="<PROJECT_NAME>"
aws resource-groups search-resources --resource-query "{\"Type\":\"TAG_FILTERS_1_0\",\"Query\":\"{\\\"ResourceTypeFilters\\\":[\\\"AWS::AllSupported\\\"],\\\"TagFilters\\\":[{\\\"Key\\\":\\\"Project\\\",\\\"Values\\\":[\\\"${PROJECT_NAME}\\\"]}]}\"}"
```
