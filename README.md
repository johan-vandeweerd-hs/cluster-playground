# Cluster playground

![](https://media1.giphy.com/media/Ppk0LL1mCFa36/giphy.gif?cid=ecf05e47e64brpzy6dlpfnsfybbrfjw1geci1wk42ac4cfar&ep=v1_gifs_search&rid=giphy.gif&ct=g)

# Setup

## Cluster

```sh
export TF_VAR_contributor="<YOUR_NAME_ALL_LOWERCASE>"
export TF_VAR_aws_region="<SOME_AWS_REGION>"
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