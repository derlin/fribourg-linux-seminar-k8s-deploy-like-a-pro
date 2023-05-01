# Rickroller with Argo CD


## Install Argo CD

Install Argo CD in your cluster with the helmfile plugin:
```bash
cd install
helmfile apply
```

Once you have argo cd, create a port forward:
```bash
kubectl port-forward -n argocd svc/argocd-server 8888:80
```

Connect to argo-cd https://localhost:8888. You will be asked to login. The user is `admin`, the initial password can
be found by typing:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Don't forget to change the password and delete the secret after first login!

## Deploy rickroller

Either use the `argocd` CLI - `app-rickroller.sh` (will use the "default" project) - or deploy it using `kubectl`:
```bash
kubectl apply -f appproject-demo.yaml # create an App Project
kubectl apply -f app-rickroller.yaml  # create an App
```

The app will be configured to sync with this repository.