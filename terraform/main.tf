# See https://github.com/exoscale/terraform-provider-exoscale/tree/master/examples/sks

terraform {
  required_providers {
    exoscale = {
      source = "exoscale/exoscale"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

variable "exoscale_api_key" { type = string }
variable "exoscale_api_secret" { type = string }

provider "exoscale" {
  key    = var.exoscale_api_key
  secret = var.exoscale_api_secret
}

locals {
  sks_zone   = "ch-gva-2"
  sks_prefix = "test"
}

# SKS cluster (control plane)
resource "exoscale_sks_cluster" "demo_sks_cluster" {
  zone          = local.sks_zone
  name          = join("-", [local.sks_prefix, "cluster"])
  service_level = "starter"
}

# (ad-hoc anti-affinity group)
resource "exoscale_anti_affinity_group" "demo_sks_anti_affinity_group" {
  name = join("-", [local.sks_prefix, "anti-affinity-group"])
}

# (ad-hoc security group)
resource "exoscale_security_group" "demo_sks_security_group" {
  name = join("-", [local.sks_prefix, "security-group"])
}

resource "exoscale_security_group_rule" "kubelet" {
  security_group_id = exoscale_security_group.demo_sks_security_group.id
  description       = "Kubelet"
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = 10250
  end_port          = 10250
  # (beetwen worker nodes only)
  user_security_group_id = exoscale_security_group.demo_sks_security_group.id
}

resource "exoscale_security_group_rule" "calico_vxlan" {
  security_group_id = exoscale_security_group.demo_sks_security_group.id
  description       = "VXLAN (Calico)"
  type              = "INGRESS"
  protocol          = "UDP"
  start_port        = 4789
  end_port          = 4789
  # (beetwen worker nodes only)
  user_security_group_id = exoscale_security_group.demo_sks_security_group.id
}

resource "exoscale_security_group_rule" "nodeport_tcp" {
  security_group_id = exoscale_security_group.demo_sks_security_group.id
  description       = "Nodeport TCP services"
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = 30000
  end_port          = 32767
  # (public)
  cidr = "0.0.0.0/0"
}

resource "exoscale_security_group_rule" "nodeport_udp" {
  security_group_id = exoscale_security_group.demo_sks_security_group.id
  description       = "Nodeport UDP services"
  type              = "INGRESS"
  protocol          = "UDP"
  start_port        = 30000
  end_port          = 32767
  # (public)
  cidr = "0.0.0.0/0"
}

# nodepool for the worker nodes
resource "exoscale_sks_nodepool" "demo_sks_nodepool" {
  cluster_id = exoscale_sks_cluster.demo_sks_cluster.id
  zone       = exoscale_sks_cluster.demo_sks_cluster.zone
  name       = join("-", [local.sks_prefix, "nodepool"])

  instance_type = "standard.small"
  size          = 2
  disk_size     = 20

  anti_affinity_group_ids = [exoscale_anti_affinity_group.demo_sks_anti_affinity_group.id]
  security_group_ids      = [exoscale_security_group.demo_sks_security_group.id]
}

# Kubeconfig to connect to the cluster
resource "exoscale_sks_kubeconfig" "demo_sks_kubeconfig" {
  cluster_id = exoscale_sks_cluster.demo_sks_cluster.id
  zone       = exoscale_sks_cluster.demo_sks_cluster.zone

  user   = "kubernetes-admin"
  groups = ["system:masters"]
}

resource "local_sensitive_file" "demo_sks_kubeconfig_file" {
  filename        = "${abspath(path.root)}/kubeconfig"
  content         = exoscale_sks_kubeconfig.demo_sks_kubeconfig.kubeconfig
  file_permission = "0600"
}

# Nginx Ingress Controller + LongHorn
# NOTE: if terraform destroy fails, type export KUBE_CONFIG_PATH=$KUBECONFIG before running destroy again
# see https://github.com/gavinbunney/terraform-provider-kubectl/issues/79

provider "kubectl" {
  config_path = local_sensitive_file.demo_sks_kubeconfig_file.filename
}

module "ingress_nginx" {
  source       = "./modules/kapply"
  manifest_url = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/exoscale/deploy.yaml"
}

# module "longhorn" {
#   source       = "./modules/kapply"
#   manifest_url = "https://raw.githubusercontent.com/longhorn/longhorn/v1.4.1/deploy/longhorn.yaml"
# }

# module "argocd" {
#   source       = "./modules/kapply"
#   manifest_url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
#   namespace    = "argocd"
# }

# data "http" "ingress_nginx" {
#   url = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/exoscale/deploy.yaml"
# }

# data "kubectl_file_documents" "ingress_nginx" {
#   content = data.http.ingress_nginx.response_body
# }

# resource "kubectl_manifest" "demo_ingress_controller_ns" {
#   # This needs to be in a specific resource, so we can use depends_on
#   yaml_body = <<YAML
# apiVersion: v1
# kind: Namespace
# metadata:
#   name: ingress-nginx
# YAML
# }

# resource "kubectl_manifest" "demo_ingress_controller" {
#   # Omit the namespace (created separately), because the order is not garanteed
#   for_each = {
#     for k, v in data.kubectl_file_documents.ingress_nginx.manifests : k => v
#     if k != "/api/v1/namespaces/ingress-nginx"
#   }
#   yaml_body = each.value
#   wait      = true

#   depends_on = [
#     kubectl_manifest.demo_ingress_controller_ns # ensure the namespace exists
#   ]
# }

# ingress controller (Helm) -- very slow! Around 2 minutes to deploy
# provider "helm" {
#   kubernetes {
#     config_path = local_sensitive_file.demo_sks_kubeconfig_file.filename
#   }
# }

# resource "helm_release" "nginx_ingress" {
#   name = "ingress-nginx"

#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   namespace  = "ingress-nginx"
# }




# Outputs

output "demo_sks_kubeconfig" {
  value = local_sensitive_file.demo_sks_kubeconfig_file.filename
}

output "demo_sks_connection" {
  value = format(
    "export KUBECONFIG=%s; kubectl cluster-info; kubectl get pods -A",
    local_sensitive_file.demo_sks_kubeconfig_file.filename,
  )
}