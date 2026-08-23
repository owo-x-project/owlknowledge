+++
version = 2
id = "constraint.storage.simple-files"
kind = "constraint"
+++

# データは単純なファイルとして保持する

OwlKnowledgeの初期データは単純なファイルとして扱い、AI自身が通常のファイル操作だけで更新できる状態を優先する。企画書に示された`.owlknowledge/sources.jsonl`・`nodes.jsonl`・`edges.jsonl`、または`.owlknowledge/sources/`・`graph.json`は初期構成の例であり、ここではどちらか一方を固定しない。
