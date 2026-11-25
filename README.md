# homelab

Proxmox VE上にTalos LinuxベースのKubernetesクラスタを構築するTerraformプロジェクト

## 概要

このリポジトリは、Proxmox Virtual Environment上にTalos LinuxベースのKubernetesクラスタを構築するためのTerraformプロジェクトです。

現在の `main.tf` で有効なのは、クラスタ用ネットワーク（VLAN 100 / vmbr100）の作成のみです。Talos VM、Talosクラスタ、Cilium、Fluxなどは、モジュールまたはコメントアウトされたコードとして用意されています。

- Control Plane: 3台
- Worker: 3台
- CNI: Cilium（`main.tf` ではコメントアウト）
- GitOps: Flux（`main.tf` ではコメントアウト）

## 構成

- **Proxmox VE**: 仮想化基盤
- **Talos Linux**: Kubernetesに特化したOS (v1.10.6)
- **Terraform**: インフラ管理
- **Terraform Cloud**: リモートバックエンド
- **Cilium**: Kubernetes CNI（`main.tf` ではコメントアウト）
- **Flux**: GitOps継続的デリバリー（`main.tf` ではコメントアウト）

## 前提条件

- Proxmox VE環境
- Terraform Cloud アカウント
- mise (ツールバージョン管理)
- Task (タスクランナー)

## セットアップ

### 1. ツールのインストール

```bash
mise install
```

### 2. Terraform初期化

```bash
terraform init
```

### 3. インフラのデプロイ

```bash
terraform apply
```

現状の `main.tf` ではネットワークのみが作成されます。Talos VMやクラスタも作成する場合は、次の手順で有効化してください。

1. `modules/proxmox-vm` を利用する `talos_vms` モジュールブロックを `main.tf` に追加する（現在は存在しません）。`vm_count` と `subnet_cidr` は必須です

   ```hcl
   module "talos_vms" {
     source = "./modules/proxmox-vm"

     node_name            = local.node_name
     vm_count             = 6
     subnet_cidr          = local.subnet_cidr
     talos_image_url      = local.talos_image_url
     talos_image_filename = "talos-${var.talos_image_version}-amd64.raw"
   }
   ```

2. `controlplane_ips` / `worker_ips` の `locals` をコメント解除する
3. `talos_cluster` モジュールと `talosconfig` / `kubeconfig` output をコメント解除する
4. `terraform init` を再実行し、追加したモジュールをインストールする
5. `terraform apply` を再実行し、VM とクラスタを作成する
6. `task kubeconfig` を実行する

**注意:** 手順5で作成されるクラスタは、`talos-config/default.yaml.tftpl` で `cni: none`、`proxy.disabled: true` が設定され、`main.tf` の Cilium リリースもコメントアウトされたままです。そのため、kubeconfig を取得しても Pod ネットワークと Service 通信は利用できず、ワークロードは実行できません。Cilium を有効化するまで、クラスタをワークロードに使用しないでください。

`ip_offset` の既定値（11）は、手順2で有効化する `controlplane_ips`（11〜13）と `worker_ips`（14〜16）の割り当てに一致します。

### 4. Talos/Kubeconfig取得

```bash
task kubeconfig
```

`talos_cluster` モジュールと `talosconfig` / `kubeconfig` output がコメントアウトされているため、上記の手順で有効化して `terraform apply` を完了するまでこのタスクは失敗します。

## タスク

Taskfileで定義されている便利なコマンド:

- `task tc` - Talosconfigを取得
- `task kc` - Kubeconfigを更新
- `task taint` - 全VMをtaint
- `task untaint` - 全VMのtaintを解除

## ネットワーク

- サブネット: `192.168.100.0/24`
- Control Plane: `192.168.100.11-13`
- Worker: `192.168.100.14-16`
- VLAN: 100 (vmbr100)

## VMスペック

`modules/proxmox-vm` の既定値:

- CPU: 4コア (x86-64-v2-AES)
- メモリ: 4GB
- ディスク1: 100GB (システム)
- ディスク2: 20GB (データ)
- ネットワーク: 2インターフェース (vmbr0, vmbr100)

## セキュリティ

- `talosconfig` にはCA証明書・クライアント証明書・秘密鍵が含まれます。リポジトリにコミットしないでください。
- `task tc` はリポジトリ直下に `talosconfig` を生成しますが、`.gitignore` で除外されています。誤ってステージしていないか `git status` で確認してください。
- 誤ってコミットした場合は、履歴から削除するだけでなく、Talosの認証情報を再生成してください。
- Proxmox API トークンなどのシークレットは環境変数から注入し、リポジトリ内のファイル（`mise.local.toml` を含む）に保存しないでください。

## ライセンス

MIT
