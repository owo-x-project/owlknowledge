+++
version = 2
id = "outcome.structure.shareable-without-source"
kind = "outcome"

[[relations]]
type = "constrained_by"
to = "constraint.project.independence"

[[relations]]
type = "verified_by"
to = "verification.knowledge.structure-sharing"
+++

# 有効なKnowledge構造をSource内容なしに転用できる

プロジェクト固有KnowledgeのSource内容を外部へ共有しなくても、Paper → Claim → Method → Experiment → Evidenceのような有効だった構造や関係定義だけを他プロジェクトへ転用できる可能性を持つ。複数プロジェクトの利用結果からStructure v1、改善、Structure v2のように構造自体を進化させ、将来的にはコミュニティが改善した構造をPRで取り込める。
