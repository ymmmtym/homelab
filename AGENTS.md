# AGENTS.md

## Project Overview

Proxmox VE 上の Talos Linux クラスタを Terraform で管理するインフラリポジトリ。
ネットワーク分離（VLAN 100）と GitOps（Flux）による自動化を実現する。

## Directory Structure

| ディレクトリ                 | 役割                                   |
| ---------------------- | ------------------------------------ |
| `modules/proxmox-vm/`  | Proxmox VM 作成 Terraform モジュール          |
| `modules/proxmox-lxc/` | Proxmox LXC 作成 Terraform モジュール         |
| `modules/talos-cluster/` | Talos クラスタ設定 Terraform モジュール         |
| `talos-config/`        | Talos マシン設定テンプレート（controlplane/worker） |
| `main.tf`              | ルート: プロバイダ設定・リソース定義                  |
| `Taskfile.yml`         | Taskfile: talosconfig/kubeconfig 操作   |

## Commands

- Terraform Init: `terraform init`
- Terraform Validate: `terraform validate`
- Terraform Format: `terraform fmt -recursive`
- Terraform Plan: `terraform plan`
- Terraform Apply: `terraform apply`
- Get Talosconfig: `task talosconfig:get`（または `task tc`）
- Update Kubeconfig: `task kubeconfig:update`（または `task kc`）

## Code Style

- Terraform: `terraform fmt` に準拠
- 変数名: スネークケース（`control_plane_ip`）
- リソース名: `module名_リソース種別` の形式
- 言語: 日本語。です/ます調で統一

## Boundaries

- `.env*` ファイルを変更・コミットしない
- Terraform state ファイルをコミットしない
- クラスタのIPアドレス・MACアドレスを外部公開しない
- 重要な判断を独断で進めない。必ず確認を求める

## Workflow

- 変更前に既存ファイルの内容を確認する
- 長時間タスクはステップ分割し、各完了後にファイル保存
- 説明には必ず具体例を含める

### Git

- ブランチ戦略は Github-flow にする
	- main ブランチ
	- feature/XXX ブランチ
