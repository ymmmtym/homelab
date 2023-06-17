terraform {
  required_version = "~> 1.5.0"

  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "~> 2.0"
    }
  }

  backend "remote" {
    organization = "yumenomatayume"
    workspaces {
      name = "homelab"
    }
  }
}
