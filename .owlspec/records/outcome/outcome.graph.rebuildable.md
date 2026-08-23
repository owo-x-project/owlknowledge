+++
version = 2
id = "outcome.graph.rebuildable"
kind = "outcome"

[[relations]]
type = "constrained_by"
to = "constraint.graph.rebuildable"
+++

# Sourceを失わずにGraphを更新・再構築できる

新しいSourceの追加やGraph構造の改善があっても、既存Sourceを破壊せずにGraphを更新できる。必要になった場合はSourceからGraphを再構築し、過去の解釈に引きずられずに理解を更新できる。
