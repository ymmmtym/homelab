# AGENTS.md

## Project Overview

Proxmox VE 上の Talos Linux クラスタを Terraform で管理するインフラリポジトリ。
ネットワーク分離（VLAN 100）と GitOps（Flux）による自動化を実現する。

## Directory Structure

| ディレクトリ            | 役割                                   |
| ----------------- | ------------------------------------ |
| `modules/`        | Terraform モジュール（VM/LXC/Talos クラスタ）      |
| `talos-config/`   | Talos マシン設定テンプレート・クラスター仕様             |
| `main.tf`         | アクティブ: ネットワークブリッジ/VLAN 設定            |

## Commands

- Lint Markdown: `npx markdownlint-cli2 "**/*.md"`
- Search content: `grep -r "keyword" output/`
- Run Test: `bun test`

## Code Style

- ファイル名: `[YYYYMMDD]-[topic].md` 形式
- 見出し: `##` から開始、`#` はファイルタイトルのみ
- 言語: 日本語。です/ます調で統一

## Boundaries

- `.env*` ファイルを変更・コミットしない
- `02_finance/` 内の金額情報を外部出力に含めない
- クライアント名・契約内容を output/ 以下のファイルに記載しない
- 重要な判断を独断で進めない。必ず確認を求める

## Workflow

- 変更前に既存ファイルの内容を確認する
- 長時間タスクはステップ分割し、各完了後にファイル保存
- 説明には必ず具体例を含める

### Git

- ブランチ戦略は Github-flow にする
	- main ブランチ
	- feature/XXX ブランチ
