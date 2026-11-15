mock_provider "proxmox" {}

variables {
  node_name            = "test-node"
  vm_count             = 3
  talos_image_url      = "https://example.invalid/talos.raw"
  talos_image_filename = "talos.raw"
  subnet_cidr          = "10.0.0.0/24"
}

run "fallback_addresses" {
  command = plan

  variables {
    vm_count   = 6
    ip_configs = [{ ipv4_address = "dhcp" }]
  }

  assert {
    condition = alltrue([
      for i, vm in proxmox_virtual_environment_vm.this :
      vm.initialization[0].ip_config[0].ipv4[0].address == "dhcp" &&
      vm.initialization[0].ip_config[1].ipv4[0].address == format("10.0.0.%d/24", i + 11)
    ])
    error_message = "各 VM の先頭インターフェースは DHCP、次のインターフェースは固有の自動割り当てアドレスになります。"
  }
}

run "multiple_vms_with_dhcp" {
  command = plan

  variables {
    ip_configs = [{ ipv4_address = "dhcp" }, { ipv4_address = "dhcp" }]
  }
}

run "reject_shared_static_address" {
  command = plan

  variables {
    ip_configs = [{ ipv4_address = "dhcp" }, { ipv4_address = "10.0.0.20/24" }]
  }

  expect_failures = [proxmox_virtual_environment_vm.this]
}

run "single_vm_static_address" {
  command = plan

  variables {
    vm_count = 1
    ip_configs = [
      { ipv4_address = "dhcp" },
      { ipv4_address = "10.0.0.20/24", ipv4_gateway = "10.0.0.1" }
    ]
  }

  assert {
    condition = (
      proxmox_virtual_environment_vm.this[0].initialization[0].ip_config[1].ipv4[0].address == "10.0.0.20/24" &&
      proxmox_virtual_environment_vm.this[0].initialization[0].ip_config[1].ipv4[0].gateway == "10.0.0.1"
    )
    error_message = "単一 VM の固定アドレスとゲートウェイは保持されます。"
  }
}
