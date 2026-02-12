variable "cluster_name" {
  type        = string
  description = "Talos cluster name"
}

variable "controlplane_ips" {
  type        = list(string)
  description = "Control plane node IPs"
}

variable "worker_ips" {
  type        = list(string)
  description = "Worker node IPs"
}

variable "controlplane_hostnames" {
  type        = list(string)
  description = "Control plane hostnames"
}

variable "worker_hostnames" {
  type        = list(string)
  description = "Worker hostnames"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets for Talos configuration"
}
