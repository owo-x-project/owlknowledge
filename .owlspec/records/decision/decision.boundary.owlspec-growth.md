+++
version = 2
id = "decision.boundary.owlspec-growth"
kind = "decision"

[[relations]]
type = "constrained_by"
to = "constraint.boundary.decision-material"
+++

# Knowledge・Owlspec・Growthの責務を分ける

OwlKnowledgeは世界やプロジェクトについての判断材料を扱い、Owlspecは確定した判断結果を扱う。OwlGrowthは経験からAI自身がどう行動を変えるかを扱う。例えば「PostgreSQLの接続プールにはこの制約がある」はOwlKnowledge、「DB障害調査では最初にpool saturationを確認する」はOwlGrowthであり、両者は概念上分離する。
