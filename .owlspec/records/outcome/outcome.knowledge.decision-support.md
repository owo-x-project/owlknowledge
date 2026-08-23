+++
version = 2
id = "outcome.knowledge.decision-support"
kind = "outcome"

[[relations]]
type = "constrained_by"
to = "constraint.boundary.decision-material"

[[relations]]
type = "constrained_by"
to = "constraint.source.uncertainty-preserved"
+++

# Sourceの関係を辿って意思決定を支援できる

OwlKnowledgeを利用すると、必要なSourceへ到達しやすくなり、関連資料、支持する主張、矛盾する主張、評価する実験、議論から生じた設計候補を関係として辿れる。単純な全文検索やベクトル検索だけでは扱いにくい「この論文は何を支持するか」「どの実験が仮説を否定したか」「議論がどの設計案につながったか」「同じ問題について別資料が何を主張するか」を扱い、Graph上の理解から根拠となるSourceへ戻れる。
