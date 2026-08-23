#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

call() {
    printf '%s\n' "$1" | OWL_KNOWLEDGE_DATA_DIR="$tmp/data" "$root/bin/owlknowledge-mcp"
}

out=$(call '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}')
printf '%s\n' "$out" | grep '"protocolVersion":"2024-11-05"' >/dev/null

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

out=$(call '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"claim-a","node_type":"Claim","label":"SQLite is sufficient","source_ids":["paper-a"],"claim_status":"hypothesis","confidence":"low"}}}')
printf '%s\n' "$out" | grep 'claim-a' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"add_node","arguments":{"node_id":"claim-b","node_type":"Claim","label":"PostgreSQL is faster","source_ids":["experiment-b"],"claim_status":"hypothesis","confidence":"low"}}}')
printf '%s\n' "$out" | grep 'claim-b' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"add_edge","arguments":{"edge_id":"edge-a","from":"source-paper-a","to":"claim-a","relation":"supports","source_ids":["paper-a"]}}}')
printf '%s\n' "$out" | grep 'edge-a' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":"add_edge","arguments":{"edge_id":"edge-b","from":"claim-a","to":"claim-b","relation":"contradicts","source_ids":["paper-a","experiment-b"]}}}')
printf '%s\n' "$out" | grep 'contradicts' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":11,"method":"tools/call","params":{"name":"rebuild_graph","arguments":{}}}')
printf '%s\n' "$out" | grep 'preserved_derived_graph' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":12,"method":"tools/call","params":{"name":"traverse_graph","arguments":{"node_id":"claim-a"}}}')
printf '%s\n' "$out" | grep 'SQLite paper' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":13,"method":"tools/call","params":{"name":"traverse_graph","arguments":{"node_id":"claim-a","limit":1}}}')
printf '%s\n' "$out" | grep 'truncated.*true' >/dev/null

out=$(call '{"jsonrpc":"2.0","id":14,"method":"tools/call","params":{"name":"export_structure","arguments":{}}}')
printf '%s\n' "$out" | grep 'supports' >/dev/null
printf '%s\n' "$out" | grep 'contradicts' >/dev/null
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

printf '%s\n' 'OwlKnowledge tests passed.'
