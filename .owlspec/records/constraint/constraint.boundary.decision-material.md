+++
version = 2
id = "constraint.boundary.decision-material"
kind = "constraint"
+++

# Knowledgeは判断材料にとどめる

OwlKnowledgeは議事録、論文、調査、実験、比較など、正しい決定を行うための材料を扱う。例えば、Paper AのSQLite案、Experiment BのPostgreSQL性能結果、Meeting Cの運用コスト優先という材料はOwlKnowledgeに置く。最終的に「このプロジェクトではSQLiteを使用する」と決定された場合のような判断結果・確定仕様は別の正本管理の責務とし、Knowledgeの内容だけで確定した真実として扱わない。
