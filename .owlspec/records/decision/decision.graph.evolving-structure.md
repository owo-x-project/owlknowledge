+++
version = 2
id = "decision.graph.evolving-structure"
kind = "decision"

[[relations]]
type = "constrained_by"
to = "constraint.graph.rebuildable"
+++

# Graph構造は利用結果に応じて進化させる

Sourceを解析し、AIがKnowledge Graphと関係を生成する。最初から巨大な固定Ontologyを定めず、少数の一般的な関係から開始する。例えばPaperからHypothesisをsupports、Methodをuses、別Paperをcontradictsし、ExperimentからHypothesisをevaluatesし、MeetingからDesignをdiscussesするような関係を扱う。

最初はDocument → Topic程度だった構造が、利用経験によってDocument → Claim → Evidence → Experiment → Decision Candidateの方が有効と判断された場合は構造を変更する。完全固定のOntologyと無制限に意味が揺れるGraphの中間を目指し、検索・理解・意思決定支援が改善する構造を採用する。
