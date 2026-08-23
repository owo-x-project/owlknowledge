+++
version = 2
id = "verification.knowledge.decision-trace"
kind = "verification"
method = "automatic"
target = "test/run.sh"
+++

# Verify decision-material tracing

Run `./test/run.sh`. The scenario connects source-linked claims with supports and contradicts relations, traverses them back to source references in stable edge order, and hard-caps oversized traversal requests at 20 related edges while reporting truncation.
