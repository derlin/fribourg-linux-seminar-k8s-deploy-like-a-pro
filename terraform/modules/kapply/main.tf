terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

data "http" "raw" {
  url = var.manifest_url
}

data "kubectl_file_documents" "docs" {
  content = data.http.raw.response_body
}

locals {
  namespace = coalesce(var.namespace, yamldecode(data.kubectl_file_documents.docs.documents[0]).metadata.name)
}

resource "kubectl_manifest" "namespace" {
  # This needs to be in a specific resource, so we can use depends_on
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${local.namespace}
YAML
}

resource "kubectl_manifest" "manifest" {
  # Omit the namespace (if any), because the order is not garanteed
  for_each = {
    for k, v in data.kubectl_file_documents.docs.manifests : k => v
    if k != "/api/v1/namespaces/${local.namespace}"
  }
  yaml_body          = each.value
  wait               = true
  override_namespace = var.namespace # Only override if provided

  depends_on = [
    kubectl_manifest.namespace # ensure the namespace exists
  ]
}