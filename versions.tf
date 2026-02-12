terraform {
  required_version = "~> 1.14.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.81"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.8"
    }
  }

  backend "remote" {
    organization = "yumenomatayume"
    workspaces {
      name = "homelab"
    }
  }
}
