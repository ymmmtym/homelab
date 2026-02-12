resource "proxmox_virtual_environment_download_file" "lxc_template" {
  count = var.template_url != null ? 1 : 0

  node_name    = var.node_name
  datastore_id = var.template_datastore_id
  content_type = "vztmpl"
  url          = var.template_url
  file_name    = var.template_filename
}

resource "proxmox_virtual_environment_container" "this" {
  count = var.container_count

  node_name = var.node_name
  vm_id     = var.vm_id_start != null ? var.vm_id_start + count.index : null

  description = var.description
  tags        = var.tags

  started = var.started

  operating_system {
    type = var.os_type
    template_file_id = var.template_url != null ? proxmox_virtual_environment_download_file.lxc_template[0].id : var.template_file_id
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mb
    swap      = var.swap_mb
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      name   = network_interface.value.name
      bridge = network_interface.value.bridge
      enabled = lookup(network_interface.value, "enabled", true)
    }
  }

  initialization {
    hostname = var.container_count > 1 ? format("%s-%02d", var.hostname_prefix, count.index + 1) : var.hostname_prefix

    dynamic "ip_config" {
      for_each = var.ip_configs
      content {
        ipv4 {
          address = ip_config.value.ipv4_address == "dhcp" ? "dhcp" : (
            var.container_count > 1 && ip_config.value.ipv4_cidr != null ?
            format("%s/%s", cidrhost(ip_config.value.ipv4_cidr, count.index + ip_config.value.ipv4_offset), split("/", ip_config.value.ipv4_cidr)[1]) :
            ip_config.value.ipv4_address
          )
          gateway = lookup(ip_config.value, "ipv4_gateway", null)
        }
      }
    }

    dynamic "dns" {
      for_each = length(var.dns_servers) > 0 ? [1] : []
      content {
        servers = var.dns_servers
        domain  = var.dns_domain
      }
    }

    user_account {
      keys     = var.ssh_keys
      password = var.root_password
    }
  }

  features {
    nesting = var.features_nesting
  }

  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      volume = mount_point.value.volume
      path   = mount_point.value.mp
    }
  }

  unprivileged = var.unprivileged
}
