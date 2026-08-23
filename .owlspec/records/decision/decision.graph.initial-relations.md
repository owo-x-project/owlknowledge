+++
version = 2
id = "decision.graph.initial-relations"
kind = "decision"

[[relations]]
type = "constrained_by"
to = "constraint.graph.rebuildable"
+++

# 初期Graphは少数の一般的な関係から始める

固定Ontologyを肥大化させず、初期状態ではreferences、supports、contradicts、derived-from、related-to、evaluatesなど少数の一般的な関係を候補とする。必要な構造はSourceと利用状況を見ながら拡張し、Schemaを増やすこと自体ではなく、検索・理解・意思決定が改善したかで構造変更を評価する。
