variable "node_name" {
  type        = string
  description = "Proxmox node name"
}

variable "container_count" {
  type        = number
  description = "Number of containers to create"
  default     = 1
}

variable "vm_id_start" {
  type        = number
  description = "Starting VM ID (optional)"
  default     = null
}

variable "hostname_prefix" {
  type        = string
  description = "Hostname prefix"
}

variable "description" {
  type        = string
  description = "Container description"
  default     = ""
}

variable "tags" {
  type        = list(string)
  description = "Container tags"
  default     = ["terraform"]
}

variable "started" {
  type        = bool
  description = "Start container after creation"
  default     = true
}

variable "os_type" {
  type        = string
  description = "Operating system type"
  default     = "ubuntu"
}

variable "template_url" {
  type        = string
  description = "LXC template URL (optional, use template_file_id if already downloaded)"
  default     = null
}

variable "template_filename" {
  type        = string
  description = "LXC template filename"
  default     = null
}

variable "template_file_id" {
  type        = string
  description = "Existing template file ID (use if template already exists)"
  default     = null
}

variable "template_datastore_id" {
  type        = string
  description = "Datastore ID for template"
  default     = "local"
}

variable "cpu_cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 1
}

variable "memory_mb" {
  type        = number
  description = "Memory in MB"
  default     = 512
}

variable "swap_mb" {
  type        = number
  description = "Swap in MB"
  default     = 512
}

variable "datastore_id" {
  type        = string
  description = "Datastore ID for container disk"
  default     = "local-lvm"
}

variable "disk_size" {
  type        = number
  description = "Disk size in GB"
  default     = 8
}

variable "network_interfaces" {
  type = list(object({
    name    = string
    bridge  = string
    enabled = optional(bool)
  }))
  description = "Network interfaces configuration"
  default = [{
    name   = "eth0"
    bridge = "vmbr0"
  }]
}

variable "ip_configs" {
  type = list(object({
    ipv4_address = optional(string)
    ipv4_cidr    = optional(string)
    ipv4_offset  = optional(number)
    ipv4_gateway = optional(string)
  }))
  description = "IP configuration for each network interface"
  default = [{
    ipv4_address = "dhcp"
  }]
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers"
  default     = []
}

variable "dns_domain" {
  type        = string
  description = "DNS domain"
  default     = null
}

variable "ssh_keys" {
  type        = list(string)
  description = "SSH public keys"
  default     = []
}

variable "root_password" {
  type        = string
  description = "Root password"
  default     = null
  sensitive   = true
}

variable "features_nesting" {
  type        = bool
  description = "Enable nesting (for Docker, etc.)"
  default     = false
}

variable "unprivileged" {
  type        = bool
  description = "Create unprivileged container"
  default     = true
}

variable "mount_points" {
  type = list(object({
    volume = string
    mp     = string
  }))
  description = "Additional mount points (e.g., for GPU passthrough). Requires root@pam authentication."
  default     = []
}
