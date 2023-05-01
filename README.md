# A Cool's Kid Guide to Deploy on Kubernetes

Want to learn Kubernetes and how to deploy a containerized application on it?
You're in the right place!

> This website/tutorial has been set up for my presentation at the 
> *24th Fribourg Linux Seminar: Kubernetes and Friends* hosted in Fribourg on **May 11th, 2023**.

In this tutorial, we will learn how to deploy the [rickroller](https://github.com/derlin/rickroller)
application to Kubernetes. You can use either a local [K3d](https://k3d.io) cluster or a
[Scalable Kubernetes Service (SKS)](
https://community.exoscale.com/documentation/sks) from [Exoscale](https://exoscale.com)
(see folder terraform - you will need some credits).

✨✨ ⮕ https://derlin.github.io/fribourg-linux-seminar-k8s-deploy-like-a-pro/

## Structure

* `terraform` → terraform module to spawn an SKS cluster on Exoscale
* `kube` → raw Kubernetes Manifests (YAML) to deploy the rickroller application
* `helm/rickroller` → a Helm Chart to deploy rickroller
* `helmfile/helmfile.yaml` → a helmfile to deploy rickroller
* `argo-cd`: AppProject and App resources to deploy rickroller using Argo CD with the helmfile plugin
    * `install/helmfile.yaml` → install Argo CD + the helmfile plugin on kubernetes
* `docs` → website sources