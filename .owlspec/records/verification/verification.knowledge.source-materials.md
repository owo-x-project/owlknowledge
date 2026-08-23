+++
version = 2
id = "verification.knowledge.source-materials"
kind = "verification"
method = "automatic"
target = "test/run.sh"
+++

# Verify diverse source materials

Run `./test/run.sh`. The scenario registers a paper and an experiment with references, project scope, status, and uncertainty, then searches the source registry. Empty source metadata, malformed graph arrays or edge evidence, duplicate nodes, and graph references to unknown sources are rejected without writing orphan records; oversized search limits remain hard-capped and bounded source projections report truncation.
