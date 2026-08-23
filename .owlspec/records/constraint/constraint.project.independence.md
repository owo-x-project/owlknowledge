+++
version = 2
id = "constraint.project.independence"
kind = "constraint"
+++

# OwlKnowledgeは独立したProjectである

OwlKnowledgeのソースコード、実行時ライブラリ、MCPランタイムは他Projectと共通化しない。OwlGrowthを含む他のOwl Projectへの実装依存や共有ソースを作らず、同じ思想を採用する場合も各Projectが独立して保守できなければならない。
