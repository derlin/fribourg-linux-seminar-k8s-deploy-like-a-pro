output "namespace" {
  description = "Namespace where the manifest was applied"
  value       = local.namespace
}

output "manifests_count" {
  description = "Number of YAML manifests applied"
  value       = length(data.kubectl_file_documents.docs.documents) + 1
}