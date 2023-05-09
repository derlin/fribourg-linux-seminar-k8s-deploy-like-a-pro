*Want to learn Kubernetes and how to deploy a containerized application on it?<br>
You're in the right place!*

Join me for a journey starting on the basics of Kubernetes, including pods, deployments, and manifests.
I'll then show you how to package your app for the cloud with [Helm](https://helm.sh).
And because a single app doesn't do much, we'll turn to [helmfile](https://helmfile.readthedocs.io/) for assistance.
Lastly, I'll mention the importance of GitOps, and demonstrate how [Argo CD](https://argo-cd.readthedocs.io/en/stable/)
can be used to automate deployments and streamline changes.

Ready? Let's get started!

!!! warning "Important"

    This website/tutorial has been set up for my presentation at the
    *24th Fribourg Linux Seminar: Kubernetes and Friends* hosted in Fribourg on **May 11th, 2023**.
    It may be outdated by the time you read it. Find the versions used later in this page.

## Kubernetes

In a single sentence:

!!! quote

    Kubernetes - or its numeronym k8s - is an open-source container orchestration platform
    that automates the deployment, scaling, and management of containerized applications.

Developed first internally by Google, it was open-sourced in 2014 and became one of the pillars of
the Cloud Native Computing Foundation. It is now ubiquitous, and supported by all major cloud providers.
It can also run locally on Docker using [minikube](https://minikube.sigs.k8s.io/) or [k3d](https://k3d.io/)!

??? example "Major managed Kubernetes providers"

    1. Amazon Web Services (AWS): [Amazon Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/)
    2. Microsoft Azure: [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-us/services/kubernetes-service/)
    3. Google Cloud Platform (GCP): [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine)
    4. IBM Cloud: [IBM Cloud Kubernetes Service](https://www.ibm.com/cloud/kubernetes-service)
    5. DigitalOcean: [DigitalOcean Kubernetes](https://www.digitalocean.com/products/kubernetes/)
    6. Oracle Cloud Infrastructure (OCI): [Oracle Kubernetes Engine (OKE)](https://www.oracle.com/kubernetes/)
    7. Alibaba Cloud: [Alibaba Cloud Container Service for Kubernetes (ACK)](https://www.alibabacloud.com/product/kubernetes)
    8. Red Hat OpenShift: [OpenShift Kubernetes Service (OKS)](https://www.openshift.com/products/kubernetes-service)
    9. Exoscale: [Scalable Kubernetes Service (SKS)](https://community.exoscale.com/documentation/sks)

The vastness and complexity of k8s is too much to take in one go. So in this pages, we will focus only on one aspect:
how to deploy an application on Kubernetes.

<div align=center>
<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/PziYflu8cB8" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
</div>

## Requirements

Here are the tools we will use, and the versions I played with:

- [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/): [v1.25.1](https://github.com/kubernetes/kubectl/releases/tag/v1.25.1)
- [Terraform](https://terraform.io/): [v1.4.5](https://github.com/hashicorp/terraform/releases/tag/v1.4.5)
- [Helm](https://helm.sh/): [v3.11.2](https://github.com/helm/helm/releases/tag/v3.11.2)
- [Helmfile](https://helmfile.readthedocs.io/): [v0.152.0](https://github.com/helmfile/helmfile/releases/tag/v0.152.0)
- [Argo CD](https://argoproj.github.io/argo-cd/): [v2.6.7](https://github.com/argoproj/argo-cd/releases/tag/v2.6.7)

## Our toy application

The application we will use is [rickroller](https://github.com/derlin/rickroller).
It is a very simple webapp coded in Python Flask, that allows you to rickroll your friends. How it works
it simple:

1. The user enters an URL,
2. Rickroller fetches the HTML content of the page, and modify it a bit so that:
    * all links redirect to a "you got rickrolled page"
    * (optional) the redirect also happens after a given number of scrolls
3. Rickroller serves the resulting HTML back to the user
4. The user can copy the URL of 3 and send it to his friends, waiting for them to get surprised.

!!! tip "Test it!" 

    A live demo is available at ⮕ [**https://tinyurl.eu.aldryn.io**](https://tinyurl.eu.aldryn.io)
    
    For the curious, it is deployed by **[Divio](https://divio.com)**, which is awesome :blue_heart:.
    Check it out!

By default, the URL generated in 3 will use the hash of the original URL, which can be quite long
(and thus suspicious).
This is why rickroller also supports an *URL shortener* mode. For this, it needs a persistence
layer to store the tuples slugs/URLs. Supported persistences are SQL (SQLite, PostgreSQL, MySQL, MariaDB, ...)
and MongoDB.

This means you can deploy rickroller using one or two images: rickroller, and the persistence.
Here is how it looks with a docker-compose:

```yaml
services:
  web:
    image: derlin/rickroller:latest
    ports: [8080:8080]
    environment:
      DATABASE_URL: postgres://postgres@db:5432/db
    links: [db]
    depends_on: [db]

  db:
    image: postgres:13.5-alpine
    environment:
      POSTGRES_DB: db
      POSTGRES_HOST_AUTH_METHOD: trust
```

Easy, right? Now, let's see how to run this same application in Kubernetes!