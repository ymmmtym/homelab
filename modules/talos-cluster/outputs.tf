output "talosconfig" {
  description = "Talos configuration file"
  value       = data.talos_client_configuration.this
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes configuration file"
  value       = talos_cluster_kubeconfig.this
  sensitive   = true
}

output "cluster_health" {
  description = "Cluster health status"
  value       = data.talos_cluster_health.this
}
