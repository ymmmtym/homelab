variable "virtual_environment_endpoint" {
  default = "https://pve-01.yumenomatayume.home:8006/"
}

variable "virtual_environment_insecure" {
  default = true
}

variable "talos_image_version" {
  type        = string
  description = "Talos Linux version"
  default     = "v1.10.6"
}

variable "vlan_id" {
  type        = number
  description = "VLAN ID for the management network"
  default     = 100
}

variable "physical_interface" {
  type        = string
  description = "Physical network interface name on the Proxmox node"
  default     = "eno1"
}
