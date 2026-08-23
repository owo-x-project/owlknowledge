+++
version = 2
id = "outcome.graph.evolves-usefully"
kind = "outcome"

[[relations]]
type = "constrained_by"
to = "constraint.graph.rebuildable"

[[relations]]
type = "constrained_by"
to = "constraint.source.uncertainty-preserved"

[[relations]]
type = "verified_by"
to = "verification.knowledge.graph-evolution"
+++

# Graph構造の改善によって理解と意思決定支援が向上する

Graph構造を利用結果に応じて改善すると、必要なSourceの発見、関連資料の理解、矛盾する主張の発見、根拠の追跡、意思決定支援が向上する。新しいSource追加後に既存理解が適切に更新されることも含め、Graphの大きさやSchemaの数ではなく、利用上の有効性で構造変更を評価できる。
