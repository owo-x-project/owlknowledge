+++
version = 2
id = "decision.search.defer-specialization"
kind = "decision"

[[relations]]
type = "constrained_by"
to = "constraint.graph.rebuildable"
+++

# 専用検索基盤は限界が確認されるまで導入しない

初期の検索は、MCP toolと単純なファイル・Graph照会で成立させる。データ量や利用上の限界が明確に観測された後に、SQLite、FTS、Embedding、Graph DBなどを候補として評価する。

技術を先に導入して検索要件を固定する案は、実際のボトルネックと異なる複雑性を持ち込むため採用しない。
