# Proxmox LXC Module

Proxmox VE上にLXCコンテナを作成するモジュール

## 使用例

### 基本的な使い方

```hcl
module "lxc" {
  source = "./modules/proxmox-lxc"

  node_name       = "pve-01"
  hostname_prefix = "ubuntu"
  template_url    = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  template_filename = "ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}
```

### 複数コンテナ作成

```hcl
module "lxc_cluster" {
  source = "./modules/proxmox-lxc"

  node_name       = "pve-01"
  container_count = 3
  hostname_prefix = "node"
  
  template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  
  cpu_cores  = 2
  memory_mb  = 2048
  disk_size  = 20
  
  ip_configs = [{
    ipv4_cidr   = "192.168.100.0/24"
    ipv4_offset = 20
    ipv4_gateway = "192.168.100.1"
  }]
}
```

### Docker対応コンテナ

```hcl
module "docker_host" {
  source = "./modules/proxmox-lxc"

  node_name       = "pve-01"
  hostname_prefix = "docker"
  
  template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  
  features_nesting = true
  unprivileged     = false
  
  cpu_cores = 4
  memory_mb = 4096
}
```

### GPU Passthrough対応コンテナ

```hcl
module "gpu_container" {
  source = "./modules/proxmox-lxc"

  node_name       = "pve-01"
  hostname_prefix = "gpu-workstation"
  
  template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  
  unprivileged = false  # GPU passthroughには特権コンテナが必要
  
  cpu_cores = 8
  memory_mb = 16384
  disk_size = 200
  
  # GPU Passthrough (Intel iGPU example)
  mount_points = [{
    key    = "0"
    slot   = 0
    volume = "/dev/dri/renderD128"
    mp     = "/dev/dri/renderD128"
  }]
}
```

## 変数

主要な変数:

- `node_name` - Proxmoxノード名（必須）
- `hostname_prefix` - ホスト名のプレフィックス（必須）
- `container_count` - 作成するコンテナ数（デフォルト: 1）
- `template_url` - LXCテンプレートURL（新規ダウンロード時）
- `template_file_id` - 既存テンプレートID（既にダウンロード済みの場合）
- `cpu_cores` - CPUコア数（デフォルト: 1）
- `memory_mb` - メモリ（MB）（デフォルト: 512）
- `disk_size` - ディスクサイズ（GB）（デフォルト: 8）
- `features_nesting` - ネスティング有効化（Docker用）（デフォルト: false）
- `unprivileged` - 非特権コンテナ（デフォルト: true）
- `mount_points` - 追加マウントポイント（GPU passthrough等）（デフォルト: []）

詳細は`variables.tf`を参照してください。

## GPU Passthrough設定

GPU Passthroughを使用する場合:

1. **特権コンテナが必要**: `unprivileged = false`
2. **デバイスをマウント**: `mount_points`でGPUデバイスを指定
3. **Proxmoxホスト側の設定**:
   ```bash
   # /dev/dri/renderD128 のパーミッション確認
   ls -l /dev/dri/
   
   # コンテナ内でGPUが認識されるか確認
   pct enter <container-id>
   ls -l /dev/dri/
   ```

### 一般的なGPUデバイス

- Intel iGPU: `/dev/dri/renderD128`
- NVIDIA GPU: `/dev/nvidia0`, `/dev/nvidiactl`, `/dev/nvidia-uvm`
- AMD GPU: `/dev/dri/renderD128`, `/dev/dri/card0`

