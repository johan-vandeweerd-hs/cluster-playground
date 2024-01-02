# Cluster playground

![](https://media1.giphy.com/media/Ppk0LL1mCFa36/giphy.gif?cid=ecf05e47e64brpzy6dlpfnsfybbrfjw1geci1wk42ac4cfar&ep=v1_gifs_search&rid=giphy.gif&ct=g)

# Setup

## Cluster

```sh
export AWS_REGION="<SOME_AWS_REGION>"
export TF_VAR_git_url="git@github.com:<USERNAME_OR_ORGANISATION>/<REPOSITORY_NAME>"
export TF_VAR_contributor="<YOUR_NAME_ALL_LOWERCASE>"
hootctl sync iam-role user-sandbox-admin -d
terraform init
terraform apply
```

When the cluster is running, you need the following commands to update your kubeconfig.

```
hootctl sync iam-role user-sandbox-admin -d
aws eks update-kubeconfig --name cluster-playground-${TF_VAR_contributor}
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
aws secretsmanager create-secret --name "cluster-playground-${TF_VAR_contributor}/argocd/ssh-key-github-com" --description "Secrets used by Argocd" --secret-string "$(cat ssh-key-github-com)"
rm ssh-key-github-com
```

# Teardown

Use following command to clean up once you are done:

```
terraform apply -destroy
```

There is still some work to be done to do a clean teardown. Following resourceds are not cleaned up automatically or are
blocking the destroy:

- EC2 instances managed by Karpenter
- Load balancers managed by AWS Load Balancer Controller
- DNS records managed by External DNS

You can use following AWS CLI command to get an idea of the resources that still exist.

```
export AWS_REGION="<SOME_AWS_REGION>"
aws resource-groups search-resources  --resource-query "{\"Type\":\"TAG_FILTERS_1_0\",\"Query\":\"{\\\"ResourceTypeFilters\\\":[\\\"AWS::AllSupported\\\"],\\\"TagFilters\\\":[{\\\"Key\\\":\\\"Contributor\\\",\\\"Values\\\":[\\\"${TF_VAR_contributor}\\\"]}]}\"}"
```