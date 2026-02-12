# homelab

Proxmox VE上にTalos LinuxベースのKubernetesクラスタを構築するTerraformプロジェクト

## 概要

このリポジトリは、Proxmox Virtual Environment上に6台のVMを作成し、Talos Linuxを使用してKubernetesクラスタを自動構築します。

- Control Plane: 3台
- Worker: 3台
- CNI: Cilium
- GitOps: Flux

## 構成

- **Proxmox VE**: 仮想化基盤
- **Talos Linux**: Kubernetesに特化したOS (v1.10.6)
- **Terraform**: インフラ管理
- **Terraform Cloud**: リモートバックエンド
- **Cilium**: Kubernetes CNI
- **Flux**: GitOps継続的デリバリー

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

### 4. Talos/Kubeconfig取得

```bash
task kubeconfig
```

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

- CPU: 4コア (x86-64-v2-AES)
- メモリ: 4GB
- ディスク1: 100GB (システム)
- ディスク2: 20GB (データ)
- ネットワーク: 2インターフェース (vmbr0, vmbr100)

## ライセンス

MIT
