# Raw Manifests to deploy rickroller on k8s

If you do not follow the tutorial at https://derlin.github.io/fribourg-linux-seminar-k8s-deploy-like-a-pro/:

* `pod.yaml` → simple pod.
* `env-depl.yaml` → deployment with the environment variable `USE_PROXY` set. This env var is required if you use an ingress later.
* `depl.yaml` → deployment without the `USE_PROXY` set.
* `svc.yaml` → Service of type ClusterIP. Use this one if you use an ingress later.
* `lb-svc.yaml` → Service of type LoadBalancer. Can be used without ingress to get a public IP.
* `ingress.yaml` → Ingress that assumes you use the Nginx Ingress Controller in your cluster.
