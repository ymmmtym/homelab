#
# local environments
#
locals {
  node_name       = "pve-01"
  subnet_cidr     = "192.168.100.0/24"
  subnet_prefix   = split("/", local.subnet_cidr)[1]
  cluster_name    = "cluster"
  talos_image_url = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/${var.talos_image_version}/nocloud-amd64.raw"
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

# vlan${var.vlan_id}
resource "proxmox_virtual_environment_network_linux_bridge" "this" {
  name      = "vmbr${var.vlan_id}"
  node_name = local.node_name
  address   = format("%s/%s", cidrhost(local.subnet_cidr, 1), local.subnet_prefix)
  ports     = ["${var.physical_interface}.${var.vlan_id}"]
}

resource "proxmox_virtual_environment_network_linux_vlan" "this" {
  node_name = local.node_name
  name      = "${var.physical_interface}.${var.vlan_id}"
  interface = var.physical_interface
}

#
# VM
#

# module "talos_vms" {
#   source = "./modules/proxmox-vm"
# 
#   node_name            = local.node_name
#   vm_count             = 6
#   subnet_cidr          = local.subnet_cidr
#   talos_image_url      = local.talos_image_url
#   talos_image_filename = "talos-v1.10.6-amd64.raw"
# }

#
# talos
#

# provider "talos" {}
# 
# locals {
#   controlplane_ips = [for i in range(11, 14) : cidrhost(local.subnet_cidr, i)]
#   worker_ips       = [for i in range(14, 17) : cidrhost(local.subnet_cidr, i)]
# }
# 
# module "talos_cluster" {
#   source = "./modules/talos-cluster"
# 
#   cluster_name             = local.cluster_name
#   controlplane_ips         = local.controlplane_ips
#   worker_ips               = local.worker_ips
#   controlplane_hostnames   = slice(module.talos_vms.vm_names, 0, 3)
#   worker_hostnames         = slice(module.talos_vms.vm_names, 3, 6)
#   subnets                  = [local.subnet_cidr]
# 
#   depends_on = [module.talos_vms]
# }
# 
# output "talosconfig" {
#   description = "Talos configuration file"
#   value       = module.talos_cluster.talosconfig
#   sensitive   = true
# }
# 
# output "kubeconfig" {
#   description = "Kubernetes configuration file"
#   value       = module.talos_cluster.kubeconfig
#   sensitive   = true
# }

#
# kubernetes
#

# provider "helm" {
#   kubernetes = {
#     host = module.talos_cluster.kubeconfig.kubernetes_client_configuration.host
# 
#     client_certificate     = base64decode(module.talos_cluster.kubeconfig.kubernetes_client_configuration.client_certificate)
#     client_key             = base64decode(module.talos_cluster.kubeconfig.kubernetes_client_configuration.client_key)
#     cluster_ca_certificate = base64decode(module.talos_cluster.kubeconfig.kubernetes_client_configuration.ca_certificate)
#   }
# }
# 
# resource "helm_release" "cilium" {
#   name       = "cilium"
#   namespace  = "kube-system"
#   repository = "https://helm.cilium.io/"
#   chart      = "cilium"
# 
#   values = [yamlencode({
#     ipam = {
#       mode = "kubernetes"
#     }
#     ingressController = {
#       enabled = true
#       default = true
#       loadbalancerMode = "shared"
#     }
#     l2announcements = {
#       enabled = true
#     }
#     kubeProxyReplacement = true
#     securityContext = {
#       capabilities = {
#         ciliumAgent = [
#           "CHOWN", "KILL", "NET_ADMIN", "NET_RAW",
#           "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE",
#           "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"
#         ]
#         cleanCiliumState = [
#           "NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"
#         ]
#       }
#     }
#     cgroup = {
#       autoMount = {
#         enabled = false
#       }
#       hostRoot = "/sys/fs/cgroup"
#     }
#     k8sServiceHost = "localhost"
#     k8sServicePort = 7445
#   })]
# 
#   timeout    = 600
#   wait       = false  # Podの起動を待たない
#   depends_on = [module.talos_cluster.cluster_health]
# }
# 
# resource "helm_release" "flux" {
#   name             = "flux"
#   repository       = "https://fluxcd-community.github.io/helm-charts"
#   chart            = "flux2"
#   namespace        = "flux-system"
#   create_namespace = true
# 
#   depends_on = [module.talos_cluster.cluster_health]
# }
# 
# resource "helm_release" "flux-sync" {
#   name             = "flux-sync"
#   repository       = "https://fluxcd-community.github.io/helm-charts"
#   chart            = "flux2-sync"
#   namespace        = "flux-system"
#   create_namespace = true
# 
#   values = [
#     yamlencode({
#       gitRepository = {
#         spec = {
#           url = "https://github.com/ymmmtym/flux"
#           ref = {
#             branch = "main"
#           }
#           interval = "1m"
#         }
#       }
#       kustomization = {
#         spec = {
#           path     = "./clusters/local"
#           prune    = true
#           interval = "10m"
#         }
#       }
#     })
#   ]
# 
#   depends_on = [helm_release.flux]
# }
# 

# #
# # Ubuntu VM
# #
# 
# # GPU PCI Mapping
# resource "proxmox_virtual_environment_hardware_mapping_pci" "igpu" {
#   name = "igpu"
#   
#   map = [{
#     id           = "8086:9bca"
#     iommu_group  = 0
#     node         = local.node_name
#     path         = "0000:00:02.0"
#     subsystem_id = "8086:2081"
#   }]
# }
# 
# resource "proxmox_virtual_environment_download_file" "ubuntu_image" {
#   node_name    = local.node_name
#   datastore_id = "local"
#   content_type = "import"
#   url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
#   file_name    = "noble-server-cloudimg-amd64.qcow2"
# }
# 
# resource "proxmox_virtual_environment_vm" "ubuntu" {
#   name      = "ubuntu-01"
#   node_name = local.node_name
#   started   = true
#   machine   = "q35"
#   bios      = "ovmf"
# 
#   stop_on_destroy = true
# 
#   cpu {
#     cores = 12
#     type  = "host"
#   }
# 
#   memory {
#     dedicated = 60 * 1024
#   }
# 
#   agent {
#     enabled = true
#   }
# 
#   serial_device {}
# 
#   hostpci {
#     device  = "hostpci0"
#     mapping = proxmox_virtual_environment_hardware_mapping_pci.igpu.name
#     pcie    = true
#   }
# 
#   efi_disk {
#     datastore_id = "local-lvm"
#     type         = "4m"
#   }
# 
#   network_device {
#     model  = "virtio"
#     bridge = "vmbr0"
#   }
# 
#   network_device {
#     model  = "virtio"
#     bridge = "vmbr100"
#   }
# 
#   disk {
#     datastore_id = "local-lvm"
#     interface    = "virtio0"
#     import_from  = proxmox_virtual_environment_download_file.ubuntu_image.id
#     iothread     = true
#     discard      = "on"
#     size         = 500
#   }
# 
#   disk {
#     datastore_id = "local-lvm"
#     interface    = "virtio1"
#     iothread     = true
#     discard      = "on"
#     size         = 100
#   }
# 
#   initialization {
#     user_account {
#       username = "ubuntu"
#       password = "ubuntu"
#     }
#     ip_config {
#       ipv4 {
#         address = "dhcp"
#       }
#     }
#     ip_config {
#       ipv4 {
#         address = format("%s/%s", cidrhost(local.subnet_cidr, 20), split("/", local.subnet_cidr)[1])
#       }
#     }
#   }
# 
#   tags = ["terraform", "ubuntu"]
# }

# #
# # LXC
# #
# 
# module "lxc" {
#   source = "./modules/proxmox-lxc"
# 
#   node_name        = local.node_name
#   hostname_prefix  = "ubuntu"
#   template_url     = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
#   template_filename = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
# 
#   cpu_cores = 12
#   memory_mb = 64 * 1024
#   disk_size = 100
# 
#   device_passthroughs = [
#     {
#       path = "/dev/dri/card0"
#       uid  = 999
#       gid  = 990
#       mode = "0660"
#     },
#     {
#       path = "/dev/dri/renderD128"
#       uid  = 999
#       gid  = 990
#       mode = "0660"
#     }
#   ]
# }
