#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

call() {
    printf '%s\n' "$1" | OWL_KNOWLEDGE_DATA_DIR="$tmp/data" "$root/bin/owlknowledge-mcp"
}

call_data() {
    printf '%s\n' "$2" | OWL_KNOWLEDGE_DATA_DIR="$1" "$root/bin/owlknowledge-mcp"
}

out=$(call '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}')
printf '%s\n' "$out" | grep '"protocolVersion":"2024-11-05"' >/dev/null

out=$(call '{"jsonrpc":"2.0","method":"ping"}')
[ -z "$out" ]

out=$(printf '%s\n' '{"jsonrpc":"1.0","method":"ping"}' '{"jsonrpc":"2.0","method":"ping"}' | OWL_KNOWLEDGE_DATA_DIR="$tmp/notification-data" "$root/bin/owlknowledge-mcp")
[ -z "$out" ]

zero_lock_data="$tmp/zero-lock-data"
mkdir -p "$zero_lock_data"
printf '%s\n' '0' > "$zero_lock_data/.owlknowledge.lock"
out=$(call_data "$zero_lock_data" '{"jsonrpc":"2.0","id":102,"method":"ping"}')
printf '%s\n' "$out" | grep '"result":{}' >/dev/null
[ ! -e "$zero_lock_data/.owlknowledge.lock" ]

out=$(printf '%s\n' '{"jsonrpc":"2.0","id":101,"method":"shutdown"}' '{"jsonrpc":"2.0","method":"exit"}' '{"jsonrpc":"2.0","id":102,"method":"ping"}' | OWL_KNOWLEDGE_DATA_DIR="$tmp/lifecycle-data" "$root/bin/owlknowledge-mcp")
[ "$(printf '%s\n' "$out" | wc -l)" -eq 1 ]
printf '%s\n' "$out" | grep '"result":null' >/dev/null

out=$(call '{"jsonrpc":"1.0","id":1,"method":"ping"}')
printf '%s\n' "$out" | grep 'requires jsonrpc 2.0' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":{"bad":1},"method":"ping"}')
printf '%s\n' "$out" | grep 'request id must be a string' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":1,"method":"ping","method":"not-found"}')
printf '%s\n' "$out" | grep 'parse error' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":1,"method":"initialize","params":false}')
printf '%s\n' "$out" | grep 'params must be an object or array' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"discover","arguments":{}}}')
printf '%s\n' "$out" | grep 'register_source' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"paper-a","title":"SQLite paper","reference":"docs/sqlite.md","source_type":"paper","project":"demo","status":"uncertain","uncertainty":"unverified claim"}}}')
printf '%s\n' "$out" | grep 'paper-a' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"experiment-b","title":"PostgreSQL benchmark","reference":"experiments/result.json","source_type":"experiment","project":"demo","status":"unverified","uncertainty":"conflicts with paper-a"}}}')
printf '%s\n' "$out" | grep 'experiment-b' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"rebuild_graph","arguments":{}}}')
printf '%s\n' "$out" | grep 'source_count.*2' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"search_sources","arguments":{"query":"unverified"}}}')
printf '%s\n' "$out" | grep 'paper-a' >/dev/null
printf '%s\n' "$out" | grep 'truncated.*false' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":61,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"source-paper-a","node_type":"Claim","label":"must not shadow source node","source_ids":[]}}}')
printf '%s\n' "$out" | grep 'node id is reserved for a Source node' >/dev/null
if grep 'must not shadow source node' "$tmp/data/nodes.jsonl" >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":62,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"bad-optional-type","title":"Bad optional type","reference":"bad.md","source_type":"paper","project":123}}}')
printf '%s\n' "$out" | grep 'requires .*string argument' >/dev/null
if grep 'bad-optional-type' "$tmp/data/sources.jsonl" >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":621,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"empty-source-fields","title":"Empty fields","reference":"empty.md","source_type":"paper","project":"","status":""}}}')
printf '%s\n' "$out" | grep 'non-empty string argument' >/dev/null
if grep 'empty-source-fields' "$tmp/data/sources.jsonl" >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":63,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"unicode-\u00e9","title":"Unicode source","reference":"unicode.md","source_type":"paper"}}}')
printf '%s\n' "$out" | grep 'unicode-' >/dev/null
out=$(call '{"jsonrpc":"2.0","id":64,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"unicode-é","title":"Duplicate Unicode source","reference":"unicode-2.md","source_type":"paper"}}}')
printf '%s\n' "$out" | grep 'source already exists' >/dev/null
out=$(call '{"jsonrpc":"2.0","id":65,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"emoji-\ud83d\ude00","title":"Emoji source","reference":"emoji.md","source_type":"paper"}}}')
printf '%s\n' "$out" | grep 'emoji-' >/dev/null
out=$(call '{"jsonrpc":"2.0","id":66,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"emoji-😀","title":"Duplicate emoji source","reference":"emoji-2.md","source_type":"paper"}}}')
printf '%s\n' "$out" | grep 'source already exists' >/dev/null
printf '%s\n' "$out" | jq -e . >/dev/null

out=$(call '{"jsonrpc":"2.0","id":67,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":" ","title":"Whitespace id","reference":"whitespace.md","source_type":"paper"}}}')
printf '%s\n' "$out" | grep 'requires a non-empty identifier' >/dev/null
if grep 'Whitespace id' "$tmp/data/sources.jsonl" >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"claim-a","node_type":"Claim","label":"SQLite is sufficient","source_ids":["paper-a"],"claim_status":"hypothesis","confidence":"low"}}}')
printf '%s\n' "$out" | grep 'claim-a' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"claim-b","node_type":"Claim","label":"PostgreSQL is faster","source_ids":["experiment-b"],"claim_status":"hypothesis","confidence":"low"}}}')
printf '%s\n' "$out" | grep 'claim-b' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":811,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"claim-b","node_type":"Claim","label":"duplicate","source_ids":["experiment-b"]}}}')
printf '%s\n' "$out" | grep 'node already exists' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":812,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"claim-duplicate-source","node_type":"Claim","label":"duplicate source citation","source_ids":["paper-a","paper-a"]}}}')
printf '%s\n' "$out" | grep 'duplicate source id' >/dev/null
if grep 'claim-duplicate-source' "$tmp/data/nodes.jsonl" >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":813,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"claim-bad-optional-type","node_type":"Claim","label":"bad optional type","source_ids":[],"description":false}}}')
printf '%s\n' "$out" | grep 'requires string argument' >/dev/null
if grep 'claim-bad-optional-type' "$tmp/data/nodes.jsonl" >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":814,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"claim-empty-fields","node_type":"Claim","label":"empty fields","source_ids":[],"claim_status":"","confidence":""}}}')
printf '%s\n' "$out" | grep 'non-empty string argument' >/dev/null
if grep 'claim-empty-fields' "$tmp/data/nodes.jsonl" >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":815,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":" ","node_type":"Claim","label":"whitespace id","source_ids":[]}}}')
printf '%s\n' "$out" | grep 'requires a non-empty string argument' >/dev/null

long_description=$(awk 'BEGIN { for (i = 1; i <= 600; i++) printf "x" }')
out=$(call "{\"jsonrpc\":\"2.0\",\"id\":81,\"method\":\"tools/call\",\"params\":{\"name\":\"add_node\",\"arguments\":{\"node_id\":\"claim-long\",\"node_type\":\"Claim\",\"label\":\"Long claim\",\"source_ids\":[\"paper-a\"],\"claim_status\":\"hypothesis\",\"confidence\":\"low\",\"description\":\"$long_description\"}}}")
printf '%s\n' "$out" | grep 'description_truncated.*true' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"add_edge","arguments":{"edge_id":"edge-a","from":"source-paper-a","to":"claim-a","relation":"supports","source_ids":["paper-a"]}}}')
printf '%s\n' "$out" | grep 'edge-a' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":"add_edge","arguments":{"edge_id":"edge-b","from":"claim-a","to":"claim-b","relation":"contradicts","source_ids":["paper-a","experiment-b"],"evidence":{"benchmark":"omit from bounded context"}}}}')
printf '%s\n' "$out" | grep 'contradicts' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":101,"method":"tools/call","params":{"name":"add_edge","arguments":{"edge_id":"edge-bad-json","from":"claim-a","to":"claim-b","relation":"related-to","evidence":{"broken":}}}}')
printf '%s\n' "$out" | grep 'parse error' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":82,"method":"tools/call","params":{"name":"add_edge","arguments":{"edge_id":"edge-long","from":"claim-a","to":"claim-long","relation":"related-to","source_ids":["paper-a"]}}}')
printf '%s\n' "$out" | grep 'edge-long' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":11,"method":"tools/call","params":{"name":"rebuild_graph","arguments":{}}}')
printf '%s\n' "$out" | grep 'preserved_derived_graph' >/dev/null
before=$(wc -l < "$tmp/data/nodes.jsonl")
call '{"jsonrpc":"2.0","id":111,"method":"tools/call","params":{"name":"rebuild_graph","arguments":{}}}' >/dev/null
after=$(wc -l < "$tmp/data/nodes.jsonl")
if [ "$before" -ne "$after" ]; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":12,"method":"tools/call","params":{"name":"traverse_graph","arguments":{"node_id":"claim-a"}}}')
printf '%s\n' "$out" | grep 'SQLite paper' >/dev/null
printf '%s\n' "$out" | grep 'docs/sqlite.md' >/dev/null
printf '%s\n' "$out" | grep 'edge-a.*edge-b' >/dev/null
printf '%s\n' "$out" | grep 'has_evidence.*true' >/dev/null
if printf '%s\n' "$out" | grep 'benchmark' >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":13,"method":"tools/call","params":{"name":"traverse_graph","arguments":{"node_id":"claim-a","limit":1}}}')
printf '%s\n' "$out" | grep 'truncated.*true' >/dev/null

n=1
while [ "$n" -le 21 ]; do
    call "{\"jsonrpc\":\"2.0\",\"id\":$((n + 21)),\"method\":\"tools/call\",\"params\":{\"name\":\"add_edge\",\"arguments\":{\"edge_id\":\"edge-bound-$n\",\"from\":\"claim-a\",\"to\":\"claim-b\",\"relation\":\"related-to\",\"source_ids\":[\"paper-a\"]}}}" >/dev/null
    n=$((n + 1))
done
out=$(call '{"jsonrpc":"2.0","id":50,"method":"tools/call","params":{"name":"traverse_graph","arguments":{"node_id":"claim-a","limit":999999}}}')
printf '%s\n' "$out" | grep 'truncated.*true' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":14,"method":"tools/call","params":{"name":"export_structure","arguments":{}}}')
printf '%s\n' "$out" | grep 'supports' >/dev/null
printf '%s\n' "$out" | grep 'contradicts' >/dev/null
printf '%s\n' "$out" | grep 'node_types.*Claim.*Source' >/dev/null
printf '%s\n' "$out" | grep 'relations.*contradicts.*supports' >/dev/null
if printf '%s\n' "$out" | grep 'docs/sqlite.md' >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":15,"method":"resources/read","params":{"uri":"owlknowledge://structure"}}')
printf '%s\n' "$out" | grep 'node_types' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":16,"method":"resources/list","params":{}}')
printf '%s\n' "$out" | grep 'owlknowledge://structure' >/dev/null
if printf '%s\n' "$out" | grep 'owlknowledge://graph' >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":17,"method":"tools/call","params":{"name":"tools/call","arguments":{}}}')
printf '%s\n' "$out" | grep 'unknown tool' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":18,"method":"tools/call","params":{"name":"register_source","arguments":{"title":"Missing reference","source_type":"paper"}}}')
printf '%s\n' "$out" | grep 'requires string argument' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":19,"method":"tools/call","params":{"name":"register_source","arguments":{"title":"","reference":"docs/empty.md","source_type":"paper"}}}')
printf '%s\n' "$out" | grep 'non-empty string' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":20,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"orphan-claim","node_type":"Claim","label":"orphan","source_ids":["missing-source"]}}}')
printf '%s\n' "$out" | grep 'unknown source' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":21,"method":"tools/call","params":{"name":"add_edge","arguments":{"edge_id":"orphan-edge","from":"claim-a","to":"claim-b","relation":"supports","source_ids":["missing-source"]}}}')
printf '%s\n' "$out" | grep 'unknown source' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":211,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"source-future","node_type":"Claim","label":"future source collision","source_ids":[]}}}')
printf '%s\n' "$out" | grep 'source-future' >/dev/null
out=$(call '{"jsonrpc":"2.0","id":212,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"future","title":"Future source","reference":"docs/future.md","source_type":"paper"}}}')
printf '%s\n' "$out" | grep 'conflicts with existing graph node' >/dev/null
if grep '"id":"future"' "$tmp/data/sources.jsonl" >/dev/null; then exit 1; fi

out=$(call '{"jsonrpc":"2.0","id":213,"method":"tools/call","params":{"name":"add_edge","arguments":{"edge_id":" ","from":"claim-a","to":"claim-b","relation":"related-to"}}}')
printf '%s\n' "$out" | grep 'requires a non-empty identifier' >/dev/null

response_data="$tmp/response-bound-data"
mkdir -p "$response_data"
response_text=$(awk 'BEGIN { for (i = 1; i <= 6000; i++) printf "r" }')
n=1
while [ "$n" -le 20 ]; do
    call_data "$response_data" "{\"jsonrpc\":\"2.0\",\"id\":$((214 + n)),\"method\":\"tools/call\",\"params\":{\"name\":\"register_source\",\"arguments\":{\"source_id\":\"response-$n\",\"title\":\"response bound $response_text\",\"reference\":\"$response_text\",\"source_type\":\"paper\",\"notes\":\"$response_text\"}}}" >/dev/null
    n=$((n + 1))
done
out=$(call_data "$response_data" '{"jsonrpc":"2.0","id":236,"method":"tools/call","params":{"name":"search_sources","arguments":{"query":"response bound","limit":20}}}')
printf '%s\n' "$out" | grep 'truncated.*bytes' >/dev/null

collision_data="$tmp/generated-id-collision-data"
mkdir -p "$collision_data"
collision_epoch=$(date +%s)
printf '%s\n' "{\"id\":\"source-src-$collision_epoch-2\",\"kind\":\"node\",\"node_type\":\"Claim\",\"label\":\"collision seed\",\"source_ids\":[],\"claim_status\":\"hypothesis\",\"confidence\":\"low\"}" > "$collision_data/nodes.jsonl"
out=$(call_data "$collision_data" '{"jsonrpc":"2.0","id":237,"method":"tools/call","params":{"name":"register_source","arguments":{"title":"collision generated","reference":"collision.md","source_type":"paper"}}}')
printf '%s\n' "$out" | grep 'Registered source reference' >/dev/null
[ "$(wc -l < "$collision_data/sources.jsonl")" -eq 1 ]

n=1
while [ "$n" -le 21 ]; do
    call "{\"jsonrpc\":\"2.0\",\"id\":$((n + 50)),\"method\":\"tools/call\",\"params\":{\"name\":\"register_source\",\"arguments\":{\"source_id\":\"bounded-source-$n\",\"title\":\"Bounded source $n\",\"reference\":\"docs/bounded-$n.md\",\"source_type\":\"paper\"}}}" >/dev/null
    n=$((n + 1))
done
out=$(call '{"jsonrpc":"2.0","id":80,"method":"tools/call","params":{"name":"search_sources","arguments":{"query":"Bounded source","limit":999999}}}')
printf '%s\n' "$out" | grep 'count.*20' >/dev/null
printf '%s\n' "$out" | grep 'truncated.*true' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":801,"method":"tools/call","params":{"name":"search_sources","arguments":{"query":"Bounded source","limit":"1"}}}')
printf '%s\n' "$out" | grep 'positive integer argument' >/dev/null
out=$(call '{"jsonrpc":"2.0","id":802,"method":"tools/call","params":{"name":"search_sources","arguments":{"query":"Bounded source","limit":0}}}')
printf '%s\n' "$out" | grep 'positive integer argument' >/dev/null

long_source=$(awk 'BEGIN { for (i = 1; i <= 6000; i++) printf "x" }')
call "{\"jsonrpc\":\"2.0\",\"id\":81,\"method\":\"tools/call\",\"params\":{\"name\":\"register_source\",\"arguments\":{\"source_id\":\"source-long\",\"title\":\"$long_source\",\"reference\":\"$long_source\",\"source_type\":\"paper\",\"notes\":\"$long_source\"}}}" >/dev/null
out=$(call '{"jsonrpc":"2.0","id":82,"method":"tools/call","params":{"name":"search_sources","arguments":{"query":"xxxxxxxx"}}}')
printf '%s\n' "$out" | grep 'title_truncated.*true' >/dev/null
printf '%s\n' "$out" | grep 'reference_truncated.*true' >/dev/null
if [ "$(printf '%s\n' "$out" | wc -c)" -gt 3000 ]; then exit 1; fi

long_source_id=$(awk 'BEGIN { for (i = 1; i <= 250; i++) printf "i" }')
out=$(call "{\"jsonrpc\":\"2.0\",\"id\":83,\"method\":\"tools/call\",\"params\":{\"name\":\"register_source\",\"arguments\":{\"source_id\":\"$long_source_id\",\"title\":\"too long\",\"reference\":\"too-long.md\",\"source_type\":\"paper\"}}}")
printf '%s\n' "$out" | grep 'identifier exceeds 249' >/dev/null
if grep "$long_source_id" "$tmp/data/sources.jsonl" >/dev/null; then exit 1; fi

if grep 'orphan-claim' "$tmp/data/nodes.jsonl" >/dev/null; then exit 1; fi
if grep 'orphan-edge' "$tmp/data/edges.jsonl" >/dev/null; then exit 1; fi

partial_data="$tmp/partial-data"
mkdir -p "$partial_data"
printf '%s' '{"id":"partial-source"' > "$partial_data/sources.jsonl"
out=$(call_data "$partial_data" '{"jsonrpc":"2.0","id":83,"method":"tools/call","params":{"name":"search_sources","arguments":{}}}')
printf '%s\n' "$out" | grep 'count.*0' >/dev/null

oversized_request=$(awk 'BEGIN { for (i = 1; i <= 66000; i++) printf "x" }')
out=$(call "{\"jsonrpc\":\"2.0\",\"id\":84,\"method\":\"ping\",\"params\":{\"padding\":\"$oversized_request\"}}")
printf '%s\n' "$out" | grep 'request exceeds 65536 characters' >/dev/null

reload_data="$tmp/reload-data"
mkdir -p "$reload_data"
printf '%s\n' '{"id":"s1","kind":"source","title":"reload source","reference":"reload.md","source_type":"paper","project":"reload","status":"unverified"}' > "$reload_data/sources.jsonl"
printf '%s\n' '{"id":"duplicate","id":"duplicate","kind":"source","title":"must be ignored","reference":"duplicate.md","source_type":"paper","project":"reload","status":"unverified"}' >> "$reload_data/sources.jsonl"
printf '%s\n' '{"id":"same-source","kind":"source","title":"first source","reference":"first.md","source_type":"paper","project":"reload","status":"unverified"}' >> "$reload_data/sources.jsonl"
printf '%s\n' '{"id":"same-source","kind":"source","title":"second source","reference":"second.md","source_type":"paper","project":"reload","status":"unverified"}' >> "$reload_data/sources.jsonl"
printf '%s\n' '{"id":"n1","kind":"node","node_type":"Claim","label":"reload claim","source_ids":["s1"],"claim_status":"hypothesis","confidence":"low"}' > "$reload_data/nodes.jsonl"
printf '%s\n' '{"id":"n1","kind":"node","node_type":"Claim","label":"must not replace","source_ids":["s1"],"claim_status":"hypothesis","confidence":"low"}' >> "$reload_data/nodes.jsonl"
printf '%s\n' '{"id":"ghost-node","kind":"node","node_type":"Claim","label":"must be ignored","source_ids":["missing"],"claim_status":"hypothesis","confidence":"low"}' >> "$reload_data/nodes.jsonl"
printf '%s\n' '{"id":"duplicate-citation","kind":"node","node_type":"Claim","label":"must be ignored","source_ids":["s1","s1"],"claim_status":"hypothesis","confidence":"low"}' >> "$reload_data/nodes.jsonl"
printf '%s\n' '{"id":"e1","kind":"edge","from":"n1","to":"n1","relation":"supports","source_ids":["s1"]}' > "$reload_data/edges.jsonl"
printf '%s\n' '{"id":"e1","kind":"edge","from":"n1","to":"n1","relation":"contradicts","source_ids":["s1"]}' >> "$reload_data/edges.jsonl"
printf '%s\n' '{"id":"eghost","kind":"edge","from":"n1","to":"ghost-node","relation":"supports","source_ids":["s1"]}' >> "$reload_data/edges.jsonl"
printf '%s\n' '{"id":"eunknown-source","kind":"edge","from":"n1","to":"n1","relation":"supports","source_ids":["missing"]}' >> "$reload_data/edges.jsonl"
out=$(call_data "$reload_data" '{"jsonrpc":"2.0","id":85,"method":"tools/call","params":{"name":"traverse_graph","arguments":{"node_id":"n1"}}}')
printf '%s\n' "$out" | grep 'e1' >/dev/null
printf '%s\n' "$out" | grep 'reload claim' >/dev/null
if printf '%s\n' "$out" | grep 'must not replace\|"relation":"contradicts"\|eghost\|ghost-node\|eunknown-source' >/dev/null; then exit 1; fi
out=$(call_data "$reload_data" '{"jsonrpc":"2.0","id":86,"method":"tools/call","params":{"name":"search_sources","arguments":{}}}')
printf '%s\n' "$out" | grep 'count.*2' >/dev/null
if printf '%s\n' "$out" | grep 'must be ignored' >/dev/null; then exit 1; fi
out=$(call_data "$reload_data" '{"jsonrpc":"2.0","id":861,"method":"tools/call","params":{"name":"search_sources","arguments":{"query":"first source"}}}')
printf '%s\n' "$out" | grep 'first source' >/dev/null
if printf '%s\n' "$out" | grep 'second source' >/dev/null; then exit 1; fi

unicode_rebuild_data="$tmp/unicode-rebuild-data"
mkdir -p "$unicode_rebuild_data"
printf '%s\n' '{"id":"s-\u00e9","kind":"source","title":"escaped source","reference":"escaped.md","source_type":"paper","project":"unicode","status":"unverified"}' > "$unicode_rebuild_data/sources.jsonl"
printf '%s\n' '{ "kind":"node", "id":"source-s-\u00e9", "claim_status":"source-material", "confidence":"not-asserted", "node_type":"Source", "label":"escaped source", "source_ids":["s-\u00e9"], "reference":"escaped.md", "status":"unverified" }' > "$unicode_rebuild_data/nodes.jsonl"
before=$(wc -l < "$unicode_rebuild_data/nodes.jsonl")
call_data "$unicode_rebuild_data" '{"jsonrpc":"2.0","id":862,"method":"tools/call","params":{"name":"rebuild_graph","arguments":{}}}' >/dev/null
after=$(wc -l < "$unicode_rebuild_data/nodes.jsonl")
[ "$before" -eq "$after" ]

malformed_lock_data="$tmp/malformed-lock-data"
mkdir -p "$malformed_lock_data"
printf '%s\n' 'not-a-pid' > "$malformed_lock_data/.owlknowledge.lock"
out=$(call_data "$malformed_lock_data" '{"jsonrpc":"2.0","id":87,"method":"ping"}')
printf '%s\n' "$out" | grep '"result":{}' >/dev/null
[ ! -e "$malformed_lock_data/.owlknowledge.lock" ]

concurrent_data="$tmp/concurrent-data"
n=1
while [ "$n" -le 4 ]; do
    printf '%s\n' '{"jsonrpc":"2.0","id":84,"method":"tools/call","params":{"name":"register_source","arguments":{"title":"concurrent source","reference":"concurrent.md","source_type":"experiment"}}}' |
        OWL_KNOWLEDGE_DATA_DIR="$concurrent_data" "$root/bin/owlknowledge-mcp" > "$tmp/source-$n.out" &
    n=$((n + 1))
done
wait
out=$(call_data "$concurrent_data" '{"jsonrpc":"2.0","id":85,"method":"tools/call","params":{"name":"search_sources","arguments":{"query":"concurrent source","limit":20}}}')
printf '%s\n' "$out" | grep 'count.*4' >/dev/null

node_data="$tmp/concurrent-nodes"
call_data "$node_data" '{"jsonrpc":"2.0","id":86,"method":"tools/call","params":{"name":"register_source","arguments":{"source_id":"node-concurrency-source","title":"node concurrency source","reference":"node.md","source_type":"experiment"}}}' >/dev/null
n=1
while [ "$n" -le 5 ]; do
    printf '%s\n' "{\"jsonrpc\":\"2.0\",\"id\":87,\"method\":\"tools/call\",\"params\":{\"name\":\"add_node\",\"arguments\":{\"node_id\":\"concurrent-node-$n\",\"node_type\":\"Claim\",\"label\":\"concurrent node\",\"source_ids\":[\"node-concurrency-source\"]}}}" |
        OWL_KNOWLEDGE_DATA_DIR="$node_data" "$root/bin/owlknowledge-mcp" > "$tmp/node-$n.out" &
    n=$((n + 1))
done
wait
[ "$(wc -l < "$node_data/nodes.jsonl")" -eq 5 ]

printf '%s\n' 'OwlKnowledge tests passed.'
