output "containers" {
  description = "Created containers"
  value       = proxmox_virtual_environment_container.this
}

output "container_ids" {
  description = "Container VM IDs"
  value       = [for c in proxmox_virtual_environment_container.this : c.vm_id]
}

output "container_names" {
  description = "Container hostnames"
  value       = [for c in proxmox_virtual_environment_container.this : c.initialization[0].hostname]
}
