# GEMINI.md

## Commands

```bash
mise install                    # install tools (terraform, talosctl, flux2)
terraform init                  # initialize Terraform
terraform plan                  # plan changes
terraform apply                 # apply changes

task tc                         # generate ./talosconfig from terraform output
task kc                         # update kubeconfig (depends on tc)
task taint                      # taint all VMs
task untaint                    # untaint all VMs
```

## Environment

- `TALOSCONFIG=./talosconfig` is set via mise.toml
- `TF_CLI_ARGS_plan` and `TF_CLI_ARGS_apply` set parallelism to 10000
- Terraform Cloud remote backend manages state

## Architecture

- `main.tf` - Active: network bridge/VLAN setup. Most resources commented out (see lines 50-335 for reference)
- `modules/proxmox-vm/` - VM creation module (currently unused)
- `modules/talos-cluster/` - Talos/Kubernetes module (currently unused)
- `modules/proxmox-lxc/` - LXC container module (currently unused)
- `talos-config/` - Talos machine config templates

## Important

- `task kc` requires `task tc` to run first (writes ./talosconfig)
- `talosconfig` is generated from `terraform output`, not static
- `proxmox_virtual_environment_vm` changes affect all 6 VMs
- `talos_machine_configuration_apply` depends on VM changes via lifecycle
- VM tags: `["terraform", "talos"]`
- VLAN 100 (vmbr100) isolates management network
- Flux GitOps repo: `https://github.com/ymmmtym/flux` (branch: main)
