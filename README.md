# Cluster playground

![](https://media1.giphy.com/media/Ppk0LL1mCFa36/giphy.gif?cid=ecf05e47e64brpzy6dlpfnsfybbrfjw1geci1wk42ac4cfar&ep=v1_gifs_search&rid=giphy.gif&ct=g)

# Setup

## Create environment

```sh
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