#
# Provider: Proxmox Virtual Environment
#
provider "proxmox" {
  endpoint = var.virtual_environment_endpoint
  insecure = var.virtual_environment_insecure
}

#
# local environments
#
locals {
  node_name = "pve-01"
}

data "proxmox_virtual_environment_node" "this" {
  node_name = local.node_name
}

data "proxmox_virtual_environment_datastores" "this" {
  node_name = local.node_name
}

#
# Network
#

# vlan100
resource "proxmox_virtual_environment_network_linux_bridge" "vlan100" {
  name      = "vlan100"
  node_name = local.node_name

  address = "192.168.100.1/24"

  vlan_aware = true

  ports = [
    "eno1.100",
  ]
}

resource "proxmox_virtual_environment_network_linux_vlan" "vlan100" {
  node_name = local.node_name
  name      = "eno1.100"
}

#
# VM
#

# Ubuntu
resource "proxmox_virtual_environment_download_file" "ubuntu_cloudimg" {
  node_name    = local.node_name
  datastore_id = "local"
  content_type = "import"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  file_name    = "jammy-server-cloudimg-amd64.qcow2"
}

resource "proxmox_virtual_environment_vm" "ubuntu-jammy" {
  name      = "ubuntu-jammy"
  node_name = local.node_name

  started = true
  on_boot = true

  cpu {
    sockets = 1
    cores   = 2
  }
  memory {
    dedicated = 2048
  }

  network_device {
    model  = "virtio"
    bridge = "vlan100"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    import_from  = proxmox_virtual_environment_download_file.ubuntu_cloudimg.id
    iothread     = true
    discard      = "on"
    size         = 5
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi1"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  initialization {
    user_account {
      username = "ubuntu"
      password = "ubuntu"
    }
    ip_config {
      ipv4 {
        address = "192.168.100.2/24"
        gateway = "192.168.100.1"
      }
    }
  }

  tags = [
    "terraform",
    "ubuntu",
  ]
}
