terraform {
  required_version = "~> 1.12.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.81"
    }
  }

  backend "remote" {
    organization = "yumenomatayume"
    workspaces {
      name = "homelab"
    }
  }
}
