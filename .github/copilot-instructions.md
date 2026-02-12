# GitHub Copilot Instructions for homelab

## プロジェクト概要

**homelab** は、自宅サーバー環境を管理するコードベースです。

Proxmox Virtual Environment 上に 6 台の VM（Control Plane 3台 + Worker 3台）を自動構築し、Talos Linux と Kubernetes を使用した本番級のクラスタを構築・管理します。

## 使用技術

### インフラストラクチャ

- **Proxmox VE**: 仮想化基盤（KVM ハイパーバイザー）
- **Terraform**: インフラコード（Infrastructure as Code）
  - Provider: `proxmox` v2.x（Proxmox VE 管理）
  - Provider: `talos` v0.9.x（Talos Linux 管理）
  - Provider: `helm` （Kubernetes リソース管理）
- **Terraform Cloud**: リモート状態管理

### OS・ミドルウェア

- **Talos Linux v1.10.6**: Kubernetes 特化型 OS
  - イメージ: `nocloud-amd64.raw`
  - ネットワーク: 2インターフェース（DHCP + 静的IP）
- **Kubernetes**: クラスタ管理
  - API Server: 6443（Control Plane）

### ネットワーク・CNI

- **Cilium**: Kubernetes ネットワークプラグイン
  - L2 Announcements: 有効
  - Ingress Controller: 有効（shared mode）
- **ネットワーク構成**:
  - サブネット: `192.168.100.0/24`
  - Control Plane IP: `192.168.100.11-13`
  - Worker IP: `192.168.100.14-16`
  - VLAN: 100（vmbr100）

### GitOps・CI/CD

- **Flux**: GitOps 継続的デリバリー
  - Repository: `https://github.com/ymmmtym/flux`
  - Branch: main
  - Sync Interval: 1分（GitRepository）、10分（Kustomization）

### ツール・管理

- **mise**: ツールバージョン管理（.tool-versions 風）
- **Task**: タスクランナー（Taskfile.yml）

## VM 仕様

| 項目 | 値 |
|------|-----|
| CPU | 4コア（x86-64-v2-AES） |
| メモリ | 4GB |
| ディスク1 | 100GB（システム） |
| ディスク2 | 20GB（データ） |
| ネットワーク | 2インターフェース（vmbr0, vmbr100） |

## ファイル構成

- `main.tf`: メインの Terraform 定義（Proxmox VM、Talos、Helm）
- `variables.tf`: 変数定義
- `versions.tf`: プロバイダバージョン指定
- `talos-config/`: Talos 設定ファイル
  - `default.yaml.tftpl`: Talos マシン設定テンプレート
- `Taskfile.yml`: Task コマンド定義
- `mise.toml` / `mise.local.toml`: ツールバージョン管理

## 重要な慣例・ルール

1. **変数の管理**: Proxmox エンドポイント、認証情報は `variables.tf` で管理
2. **タグ付け**: VM には `["terraform", "talos"]` タグを付与
3. **ネットワーク設定**: VLAN 100 で管理ネットワークを分離
4. **Flux 同期**: GitOps リポジトリを信頼できるソースとして使用
5. **自動起動**: VM の `on_boot` フラグで起動時の動作制御

## よく使うコマンド

```bash
# ツールの初期化
mise install

# Terraform 実行
terraform init
terraform plan
terraform apply

# 設定ファイルの取得
task tc          # Talosconfig
task kc          # Kubeconfig

# VM 管理
task taint       # 全 VM に taint を追加
task untaint     # 全 VM の taint を削除
```

## コード変更時の注意点

- `proxmox_virtual_environment_vm` リソースの変更は全 VM に影響します
- `talos_machine_configuration_apply` は lifecycle で VM 変更に依存しています
- Terraform Cloud に接続できない場合でも、ローカル状態で計画確認は可能です
