+++
version = 2
id = "decision.boundary.tool-agnostic"
kind = "decision"
+++

# 他のOwlツールへ依存しない

OwlKnowledge自身はOwlspecやOwlGrowthを認知せず、専用Integration APIも基本的には設けない。`./docs/foo.md`、`./experiments/result.json`、`./spec/design.md`、`https://example.com/paper`のようなSourceを参照するだけでよく、そのファイルが別のOwlツール管理下にあるかどうかは責務外とする。AIが必要に応じて意味的に横断利用する。
