output "vms" {
  description = "Created VMs"
  value       = proxmox_virtual_environment_vm.this
}

output "vm_names" {
  description = "VM names"
  value       = [for vm in proxmox_virtual_environment_vm.this : vm.name]
}
