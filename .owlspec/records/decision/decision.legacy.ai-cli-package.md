+++
version = 2
id = "decision.legacy.ai-cli-package"
kind = "decision"
retired = true
+++

# 企画書に記載されたAI CLI/APM導入案（現在は不採用）

企画書には、AI CLIネイティブ機能でどこまで実現できるかを最初に検証し、APMによってSkillとして導入する案が記載されていた。初期構成として`sources.jsonl`・`nodes.jsonl`・`edges.jsonl`、または`sources/`・`graph.json`を置き、AI自身の通常ファイル操作を優先し、必要な場合のみbash + jq等を導入する案である。検索も最初はgrep/ripgrep、ファイル検索、Agent context、native toolsを使い、限界が確認されてからSQLite、FTS、Embedding、Graph DBを検討する段階案が記載されていた。

これは企画書上の旧案を履歴として保持するrecordであり、現在のMCP-only・sh+awk方針では採用しない。
