# Cluster playground

![](https://media1.giphy.com/media/Ppk0LL1mCFa36/giphy.gif?cid=ecf05e47e64brpzy6dlpfnsfybbrfjw1geci1wk42ac4cfar&ep=v1_gifs_search&rid=giphy.gif&ct=g)

# Setup

## Cluster

### Create

```shell
export AWS_REGION="<SOME_AWS_REGION>"
export TF_VAR_project_name="<PROJECT_NAME>"
export TF_VAR_git_url="git@github.com:<USERNAME_OR_ORGANISATION>/<REPOSITORY_NAME>"
export TF_VAR_git_revision="<BRANCH_NAME>"
terraform init
terraform apply -target module.network
terraform apply -target module.cluster
terraform apply -target module.platform
```

When the cluster is running, you need the following commands to update your kubeconfig.

```
aws eks update-kubeconfig --name ${TF_VAR_project_name} --alias ${TF_VAR_project_name} 
```

### Destroy

```shell
terraform apply -target module.platform -destroy
kubectl delete poddisruptionbudget -A --all
kubectl delete nodepool --all
kubectl delete nodeclaims --all
kubectl delete ec2nodeclass --all
terraform apply -target module.cluster -destroy
terraform apply -target module.network -destroy
```

## Argocd

To access Argocd, port-forward the Argocd server to a local port.

```
kubectl port-forward -n argocd service/argo-cd-argocd-server 8000:443
```

Browse to [https://localhost:8000](https://localhost:8000) and login with username `admin`.  
Get the password from the`argocd-initial-admin-secret`

```
kubectl get secret -n argocd argocd-initial-admin-secret -ojson | jq -r '.data.password' | base64 -d 
```

## Git SSH key (optional)

If you want Argocd to use a private Github repostiories, you need to add the necessary SSH keys to Secrets Manager.

```
vi ssh-key-github-com
aws secretsmanager create-secret --name "${TF_VAR_project_name}/argocd/ssh-key-github-com" --description "Secrets used by Argocd" --secret-string "$(cat ssh-key-github-com)"
rm ssh-key-github-com
```

# Teardown

You can use following AWS CLI command to get an idea of the resources that still exist.

```
export AWS_REGION="<SOME_AWS_REGION>"
aws resource-groups search-resources  --resource-query "{\"Type\":\"TAG_FILTERS_1_0\",\"Query\":\"{\\\"ResourceTypeFilters\\\":[\\\"AWS::AllSupported\\\"],\\\"TagFilters\\\":[{\\\"Key\\\":\\\"Project\\\",\\\"Values\\\":[\\\"${TF_VAR_project_name}\\\"]}]}\"}"
```
