# Deploy an SKS cluster

This terraform module will spawn an SKS cluster on Exoscale
with two nodes, and optionally install the nginx controller
and longhorn (comment/uncomment in the `main.tf` file).

You need to have an API key and an API secret from Exoscale:

Install:
```bash
export TF_VAR_exoscale_api_key=$EXOSCALE_API_KEY
export TF_VAR_exoscale_api_secret=$EXOSCALE_API_SECRET

terraform init
terraform apply -auto-approve
```

You can now connect to the Kubernetes cluster by using the
generated kubeconfig at the root of the terraform folder:
```bash
export KUBECONFIG=terraform/kubeconfig
kubectl cluster-info
```

Uninstall:
```bash
terraform destroy -auto-approuve
```

**NOTE**: if you have trouble uninstalling, it may come from the `kapply` custom module,
which uses the `gavinbunney/kubectl` provided. The latter is a bit unstable.
If you encounter errors:

* comment everything related to `kapply` in the `main.tf` file
* run `terraform apply`, it will uninstall nginx controller and such
* now, run `terraform destroy`