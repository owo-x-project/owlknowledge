+++
version = 2
id = "verification.knowledge.structure-sharing"
kind = "verification"
method = "automatic"
target = "test/run.sh"
+++

# Verify source-free structure sharing

Run `./test/run.sh`. The structure export and sole graph resource contain node and relation types but no source path or source content; targeted graph context is obtained through `traverse_graph`.
