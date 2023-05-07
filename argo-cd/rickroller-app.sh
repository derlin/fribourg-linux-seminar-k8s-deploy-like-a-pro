#!/usr/bin/env bash

# This is equivalent to running kubectl apply -f app-rickroller.yaml
# It is just an example on how to use the argocd CLI
argocd app create rickroller \
    --project demo \
    --repo https://github.com/derlin/fribourg-linux-seminar-k8s-deploy-like-a-pro --path helmfile \
    --dest-server https://kubernetes.default.svc --dest-namespace rickroller \
    --set-finalizer \
    --sync-option CreateNamespace=true \
    --sync-policy automated --self-heal --auto-prune \
    --upsert