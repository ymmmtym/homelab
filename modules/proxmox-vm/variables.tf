variable "node_name" {
  type        = string
  description = "Proxmox node name"
}

variable "vm_count" {
  type        = number
  description = "Number of VMs to create"
}

variable "vm_name_prefix" {
  type        = string
  description = "VM name prefix"
  default     = "talos"
}

variable "cpu_cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 4
}

variable "cpu_type" {
  type        = string
  description = "CPU type"
  default     = "x86-64-v2-AES"
}

variable "memory_mb" {
  type        = number
  description = "Memory in MB"
  default     = 4096
}

variable "datastore_id" {
  type        = string
  description = "Datastore ID for disks"
  default     = "local-lvm"
}

variable "disk_size_system" {
  type        = number
  description = "System disk size in GB"
  default     = 100
}

variable "disk_size_data" {
  type        = number
  description = "Data disk size in GB"
  default     = 20
}

variable "network_bridges" {
  type        = list(string)
  description = "List of network bridges"
  default     = ["vmbr0", "vmbr100"]
}

variable "ip_configs" {
  type = list(object({
    ipv4_address = string
    ipv4_gateway = optional(string)
  }))
  description = "IP configurations per network interface (one entry per interface)"
  default     = []
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR for IP assignment (legacy, use ip_configs instead)"
  default     = ""
}

variable "ip_offset" {
  type        = number
  description = "IP offset from subnet base (legacy, use ip_configs instead)"
  default     = 11
}

variable "talos_image_url" {
  type        = string
  description = "Talos image URL"
}

variable "talos_image_filename" {
  type        = string
  description = "Talos image filename"
}

variable "tags" {
  type        = list(string)
  description = "VM tags"
  default     = ["terraform", "talos"]
}
