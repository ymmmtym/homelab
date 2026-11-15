resource "proxmox_virtual_environment_download_file" "talos_image" {
  node_name    = var.node_name
  datastore_id = "local"
  content_type = "import"
  url          = var.talos_image_url
  file_name    = var.talos_image_filename
}

resource "proxmox_virtual_environment_vm" "this" {
  count = var.vm_count

  name      = format("%s-%02d", var.vm_name_prefix, count.index + 1)
  node_name = var.node_name

  started = true
  on_boot = false

  cpu {
    sockets = 1
    cores   = var.cpu_cores
    type    = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
  }

  agent {
    enabled = true
  }

  dynamic "network_device" {
    for_each = var.network_bridges
    content {
      model  = "virtio"
      bridge = network_device.value
    }
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    import_from  = proxmox_virtual_environment_download_file.talos_image.id
    discard      = "on"
    size         = var.disk_size_system
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi1"
    discard      = "on"
    size         = var.disk_size_data
  }

  initialization {
    dynamic "ip_config" {
      for_each = var.network_bridges
      content {
        ipv4 {
          address = ip_config.key < length(var.ip_configs) ? var.ip_configs[ip_config.key].ipv4_address : (
            ip_config.key == 0 ? "dhcp" : format("%s/%s", cidrhost(var.subnet_cidr, count.index + var.ip_offset), split("/", var.subnet_cidr)[1])
          )
          gateway = ip_config.key < length(var.ip_configs) ? try(var.ip_configs[ip_config.key].ipv4_gateway, null) : null
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = var.vm_count <= 1 || alltrue([
        for config in var.ip_configs : config.ipv4_address == "dhcp"
      ])
      error_message = "ip_configs の明示的な固定 IPv4 アドレスは vm_count = 1 の場合のみ指定できます。複数 VM では DHCP または subnet_cidr と ip_offset による自動割り当てを使用してください。"
    }
  }

  tags = var.tags
}
