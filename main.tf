provider "proxmox" {
  pm_api_url = var.pm_api_url

  pm_tls_insecure = true
  pm_debug        = true
}

resource "proxmox_vm_qemu" "ubuntu" {
  name        = "ubuntu"
  target_node = "pve-01"
  clone       = "ubuntu-22.04"
  memory      = 2048
  os_type     = "cloud-init"

  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "20G"
  }
}
