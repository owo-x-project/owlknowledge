# OwlKnowledge

[英語版](README.md)

## プロジェクト概要

OwlKnowledgeは、議事録・論文・調査結果・実験結果などの資料を、参照可能な知識グラフへ整理する、軽量なMCPサーバーです。元の資料を材料として保持し、グラフは再構築可能な派生物として扱います。

## コンセプト

資料の内容を正本として保持し、AIが解釈した項目と関係を知識グラフとして管理します。グラフ上の主張は決定事項ではなく、根拠・不確実性・矛盾を残したまま更新できます。

## 解決するシナリオ

- 分散した資料から、関連する根拠や主張へ到達する
- ある仮説を支持・否定する資料や実験を関係として辿る
- 元の資料を失わずに、用途に合わせてグラフ構造を再構築・改善する

## 導入方法

APMを使う場合:

```sh
apm install owo-x-project/owlknowledge --target codex,claude
```

ソースから使う場合:

```sh
git clone https://github.com/owo-x-project/owlknowledge.git
cd owlknowledge
./bin/owlknowledge-mcp
```

## ライセンス

MITライセンス。詳細は [ライセンス本文](LICENSE) を参照してください。
