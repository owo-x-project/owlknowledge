+++
version = 2
id = "verification.knowledge.source-materials"
kind = "verification"
method = "automatic"
target = "test/run.sh"
+++

# Verify diverse source materials

Run `./test/run.sh`. The scenario registers a paper and an experiment with references, project scope, status, and uncertainty, then searches the source registry. It verifies that id-less JSON-RPC notifications emit no response and rejects malformed JSON-RPC lines, wrong protocol versions, non-scalar request ids, empty source metadata, malformed graph arrays or edge evidence, duplicate nodes, reserved Source-node id collisions, and graph references to unknown sources without writing orphan or conflicting records; oversized search limits remain hard-capped and bounded source projections report truncation.
