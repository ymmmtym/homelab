resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.controlplane_ips[0]}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.controlplane_ips[0]}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = var.controlplane_ips
  nodes                = var.worker_ips
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = { for k, v in var.controlplane_ips : k => v }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value
  config_patches = [
    templatefile("${path.root}/talos-config/default.yaml.tftpl", {
      hostname = var.controlplane_hostnames[each.key]
      subnets  = var.subnets
      type     = "controlplane"
    })
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = { for k, v in var.worker_ips : k => v }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value
  config_patches = [
    templatefile("${path.root}/talos-config/default.yaml.tftpl", {
      hostname = var.worker_hostnames[each.key]
      subnets  = var.subnets
      type     = "worker"
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.controlplane_ips[0]

  lifecycle {
    replace_triggered_by = [talos_machine_configuration_apply.controlplane]
  }

  depends_on = [talos_machine_configuration_apply.controlplane]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.controlplane_ips[0]

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
  control_plane_nodes    = var.controlplane_ips
  worker_nodes           = var.worker_ips
  endpoints              = data.talos_client_configuration.this.endpoints
  skip_kubernetes_checks = true

  timeouts = {
    read = "20m"
  }
}
