+++
version = 2
id = "constraint.graph.rebuildable"
kind = "constraint"
+++

# GraphはSourceから再構築できる派生物とする

Sourceを正本とし、解析を経てKnowledge Graphを生成する。GraphはAIによる理解として自由に変更・再構築できる派生物とし、Graphの変更や解析の失敗によってSourceそのものを破壊してはならない。Sources → rebuild → Graphを常に可能にする。
