#
# local environments
#
locals {
  node_name     = "pve-01"
  subnet_cidr   = "192.168.100.0/24"
  subnet_prefix = split("/", local.subnet_cidr)[1]
}

#
# Provider: Proxmox Virtual Environment
#
provider "proxmox" {
  endpoint = var.virtual_environment_endpoint
  insecure = var.virtual_environment_insecure
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
resource "proxmox_virtual_environment_network_linux_bridge" "vmbr100" {
  name      = "vmbr100"
  node_name = local.node_name
  address   = format("%s/%s", cidrhost(local.subnet_cidr, 1), local.subnet_prefix)
  ports     = ["eno1.100"]
}

resource "proxmox_virtual_environment_network_linux_vlan" "vlan100" {
  node_name = local.node_name
  name      = "eno1.100"
  interface = "eno1"
}

#
# VM
#

resource "proxmox_virtual_environment_download_file" "talos_v1_10_6_amd64_img" {
  node_name    = local.node_name
  datastore_id = "local"
  content_type = "import"
  url          = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.10.6/nocloud-amd64.raw"
  file_name    = "talos-v1.10.6-amd64.raw"
}

resource "proxmox_virtual_environment_vm" "talos" {
  count = 6

  name      = format("talos-%02d", count.index + 1)
  node_name = local.node_name

  started = true
  on_boot = true

  cpu {
    sockets = 1
    cores   = 4
    type    = "x86-64-v2-AES"
  }
  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    model  = "virtio"
    bridge = "vmbr0"
  }
  network_device {
    model  = "virtio"
    bridge = "vmbr100"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    import_from  = proxmox_virtual_environment_download_file.talos_v1_10_6_amd64_img.id
    discard      = "on"
    size         = 100
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi1"
    discard      = "on"
    size         = 20
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    ip_config {
      ipv4 {
        address = format("%s/%s", cidrhost(local.subnet_cidr, count.index + 11), local.subnet_prefix)
      }
    }
  }

  tags = ["terraform", "talos", ]
}

#
# talos
#

locals {
  cluster_name     = "cluster"
  controlplane_ips = [for i in range(11, 14) : cidrhost(local.subnet_cidr, i)]
  worker_ips       = [for i in range(14, 17) : cidrhost(local.subnet_cidr, i)]
}

provider "talos" {}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = local.cluster_name
  cluster_endpoint = "https://${local.controlplane_ips[0]}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = local.cluster_name
  cluster_endpoint = "https://${local.controlplane_ips[0]}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.controlplane_ips
  nodes                = local.worker_ips
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = { for k, v in local.controlplane_ips : k => v }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value
  config_patches = [
    templatefile("${path.module}/talos-config/default.yaml.tftpl", {
      hostname = proxmox_virtual_environment_vm.talos[each.key].name
      subnets = [local.subnet_cidr]
      type    = "controlplane"
    })
  ]

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.talos]
  }

  depends_on = [proxmox_virtual_environment_vm.talos]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = { for k, v in local.worker_ips : k => v }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value
  config_patches = [
    templatefile("${path.module}/talos-config/default.yaml.tftpl", {
      hostname = proxmox_virtual_environment_vm.talos[each.key + 3].name
      subnets = [local.subnet_cidr]
      type    = "worker"
    }),
  ]

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.talos]
  }

  depends_on = [proxmox_virtual_environment_vm.talos]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplane_ips[0]

  lifecycle {
    replace_triggered_by = [talos_machine_configuration_apply.controlplane]
  }

  depends_on = [talos_machine_configuration_apply.controlplane]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplane_ips[0]

  lifecycle {
    replace_triggered_by = [talos_machine_bootstrap.this]
  }

  depends_on = [talos_machine_secrets.this]
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker,
    talos_machine_bootstrap.this
  ]
  client_configuration   = data.talos_client_configuration.this.client_configuration
  control_plane_nodes    = local.controlplane_ips
  worker_nodes           = local.worker_ips
  endpoints              = data.talos_client_configuration.this.endpoints
  skip_kubernetes_checks = true

  timeouts = {
    read = "20m"
  }
}

output "talosconfig" {
  description = "Talos configuration file"
  value       = data.talos_client_configuration.this
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes configuration file"
  value       = talos_cluster_kubeconfig.this
  sensitive   = true
}

#
# Helm
#

provider "helm" {
  kubernetes = {
    host = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host

    client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  }
}

resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"

  values = [yamlencode({
    ipam = {
      mode = "kubernetes"
    }

    l2announcements = {
      enabled = true
    }

    kubeProxyReplacement = true

    securityContext = {
      capabilities = {
        ciliumAgent = [
          "CHOWN", "KILL", "NET_ADMIN", "NET_RAW",
          "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE",
          "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"
        ]
        cleanCiliumState = [
          "NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"
        ]
      }
    }

    cgroup = {
      autoMount = {
        enabled = false
      }
      hostRoot = "/sys/fs/cgroup"
    }

    k8sServiceHost = "localhost"
    k8sServicePort = 7445
  })]

  depends_on = [data.talos_cluster_health.this]
}

resource "helm_release" "flux" {
  name       = "flux"
  namespace  = "flux-system"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"

  create_namespace = true

  depends_on = [data.talos_cluster_health.this]
}
