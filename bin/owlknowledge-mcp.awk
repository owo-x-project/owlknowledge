# OwlKnowledge's only product boundary is MCP over stdio.
# This file intentionally uses only POSIX awk.

BEGIN {
    source_file = data_dir "/sources.jsonl"
    node_file = data_dir "/nodes.jsonl"
    edge_file = data_dir "/edges.jsonl"
    sequence = 0
    MAX_CONTEXT_ITEMS = 20
    MAX_CONTEXT_TEXT = 512
    MAX_IDENTIFIER_TEXT = 256
    MAX_SOURCE_IDENTIFIER_TEXT = 249
    MAX_REQUEST_TEXT = 65536
    MAX_RESPONSE_TEXT = 32768
    REQUEST_NOTIFICATION = 0
    SHUTDOWN_REQUESTED = 0
    load_sources(); load_nodes(); load_edges()
}

{ if ($0 !~ /^[[:space:]]*$/) handle_request($0) }

function ws(s, i) { while (i <= length(s) && substr(s, i, 1) ~ /[[:space:]]/) i++; return i }

function string_end(s, i, c) {
    i++
    while (i <= length(s)) {
        c = substr(s, i, 1)
        if (c == "\\") i += 2
        else if (c == "\"") return i
        else i++
    }
    return -1
}

function value_end(s, i, c, open, closer, depth) {
    i = ws(s, i); c = substr(s, i, 1)
    if (c == "\"") return string_end(s, i)
    if (c == "{" || c == "[") {
        for (open in value_stack) delete value_stack[open]
        value_stack[1] = c; depth = 1; i++
        while (i <= length(s)) {
            c = substr(s, i, 1)
            if (c == "\"") i = string_end(s, i)
            else if (c == "{" || c == "[") { value_stack[++depth] = c }
            else if (c == "}" || c == "]") {
                if ((value_stack[depth] == "{" && c == "}") || (value_stack[depth] == "[" && c == "]")) {
                    delete value_stack[depth]
                    depth--
                    if (depth == 0) return i
                }
            }
            i++
        }
        return -1
    }
    while (i <= length(s)) {
        c = substr(s, i, 1)
        if (c == "," || c == "}" || c == "]" || c ~ /[[:space:]]/) return i - 1
        i++
    }
    return length(s)
}

function object_get(obj, wanted, i, e, k_end, key, start, c) {
    GET_PRESENT = 0; GET_RAW = ""; GET_STRING = ""
    i = ws(obj, 1); if (substr(obj, i, 1) != "{") return 0
    i = ws(obj, i + 1)
    while (i <= length(obj) && substr(obj, i, 1) != "}") {
        if (substr(obj, i, 1) != "\"") return 0
        k_end = string_end(obj, i); if (k_end < 0) return 0
        key = json_decode(substr(obj, i, k_end - i + 1)); i = ws(obj, k_end + 1)
        if (substr(obj, i, 1) != ":") return 0
        start = ws(obj, i + 1); e = value_end(obj, start); if (e < start) return 0
        if (key == wanted) {
            GET_PRESENT = 1; GET_RAW = substr(obj, start, e - start + 1); c = substr(GET_RAW, 1, 1)
            if (c == "\"") GET_STRING = json_decode(GET_RAW)
            return 1
        }
        i = ws(obj, e + 1)
        if (substr(obj, i, 1) == ",") i = ws(obj, i + 1)
        else if (substr(obj, i, 1) != "}") return 0
    }
    return 0
}

function json_decode(s, i, c, out, hex, n, low_hex, low) {
    out = ""; i = 2
    while (i < length(s)) {
        c = substr(s, i, 1)
        if (c == "\\") {
            i++; c = substr(s, i, 1)
            if (c == "n") out = out "\n"
            else if (c == "r") out = out "\r"
            else if (c == "t") out = out "\t"
            else if (c == "b") out = out "\b"
            else if (c == "f") out = out "\f"
            else if (c == "u" && i + 4 < length(s)) {
                hex = substr(s, i + 1, 4); n = hex_value(hex)
                if (n >= 55296 && n <= 56319 && substr(s, i + 5, 2) == "\\u") {
                    low_hex = substr(s, i + 7, 4); low = hex_value(low_hex)
                    if (low >= 56320 && low <= 57343) { n = 65536 + (n - 55296) * 1024 + low - 56320; out = out utf8_encode(n); i += 10 }
                    else { out = out "\\u" hex; i += 4 }
                } else if (n >= 55296 && n <= 57343) { out = out "\\u" hex; i += 4 }
                else if (n == 8) { out = out "\b"; i += 4 }
                else if (n == 9) { out = out "\t"; i += 4 }
                else if (n == 10) { out = out "\n"; i += 4 }
                else if (n == 12) { out = out "\f"; i += 4 }
                else if (n == 13) { out = out "\r"; i += 4 }
                else if (n < 32) { out = out "\\u" hex; i += 4 }
                else { out = out utf8_encode(n); i += 4 }
            } else out = out c
        } else if (c == "\"") return out
        else out = out c
        i++
    }
    return out
}

function utf8_encode(n) {
    if (n < 128) return sprintf("%c", n)
    if (n < 2048) return sprintf("%c%c", 192 + int(n / 64), 128 + (n % 64))
    if (n < 65536) return sprintf("%c%c%c", 224 + int(n / 4096), 128 + (int(n / 64) % 64), 128 + (n % 64))
    return sprintf("%c%c%c%c", 240 + int(n / 262144), 128 + (int(n / 4096) % 64), 128 + (int(n / 64) % 64), 128 + (n % 64))
}

function hex_value(s, i, c, p, n) {
    n = 0
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1); p = index("0123456789abcdefABCDEF", c)
        if (p == 0) return -1
        if (p <= 10) n = n * 16 + p - 1
        else if (p <= 16) n = n * 16 + p - 1 - 10 + 10
        else n = n * 16 + p - 1 - 16 + 10
    }
    return n
}

function json_escape(s, i, c, out) {
    out = "\""
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") out = out "\\\\"
        else if (c == "\"") out = out "\\\""
        else if (c == "\n") out = out "\\n"
        else if (c == "\r") out = out "\\r"
        else if (c == "\t") out = out "\\t"
        else if (c == "\b") out = out "\\b"
        else if (c == "\f") out = out "\\f"
        else out = out c
    }
    return out "\""
}

function json_skip_ws(s) { while (JSON_POS <= length(s) && substr(s, JSON_POS, 1) ~ /[[:space:]]/) JSON_POS++ }

function json_parse_string(s, c, hex) {
    if (substr(s, JSON_POS, 1) != "\"") { JSON_OK = 0; return }
    JSON_POS++
    while (JSON_POS <= length(s)) {
        c = substr(s, JSON_POS, 1)
        if (c == "\"") { JSON_POS++; return }
        if (c ~ /[[:cntrl:]]/) { JSON_OK = 0; return }
        if (c == "\\") {
            JSON_POS++; c = substr(s, JSON_POS, 1)
            if (c == "u") {
                hex = substr(s, JSON_POS + 1, 4)
                if (length(hex) != 4 || hex !~ /^[0-9a-fA-F]{4}$/) { JSON_OK = 0; return }
                JSON_POS += 5
            } else if (c == "\"" || c == "\\" || c == "/" || c == "b" || c == "f" || c == "n" || c == "r" || c == "t") JSON_POS++
            else { JSON_OK = 0; return }
        } else JSON_POS++
    }
    JSON_OK = 0
}

function json_parse_number(s, fragment) {
    fragment = substr(s, JSON_POS)
    if (match(fragment, /^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?/) != 1) { JSON_OK = 0; return }
    JSON_POS += RLENGTH
}

function json_parse_array(s, c) {
    JSON_POS++; json_skip_ws(s)
    if (substr(s, JSON_POS, 1) == "]") { JSON_POS++; return }
    while (JSON_OK) {
        json_parse_value(s); if (!JSON_OK) return
        json_skip_ws(s); c = substr(s, JSON_POS, 1)
        if (c == "]") { JSON_POS++; return }
        if (c != ",") { JSON_OK = 0; return }
        JSON_POS++; json_skip_ws(s)
    }
}

function json_parse_object(s, c, key_start, key_end, key, depth, marker) {
    JSON_OBJECT_DEPTH++; depth = JSON_OBJECT_DEPTH
    for (marker in json_object_keys) if (substr(marker, 1, length(depth) + 1) == depth SUBSEP) delete json_object_keys[marker]
    JSON_POS++; json_skip_ws(s)
    if (substr(s, JSON_POS, 1) == "}") { JSON_POS++; JSON_OBJECT_DEPTH--; return }
    while (JSON_OK) {
        key_start = JSON_POS; json_parse_string(s); if (!JSON_OK) { JSON_OBJECT_DEPTH--; return }
        key_end = JSON_POS; key = json_decode(substr(s, key_start, key_end - key_start)); marker = depth SUBSEP key
        if (marker in json_object_keys) { JSON_OK = 0; JSON_OBJECT_DEPTH--; return }
        json_object_keys[marker] = 1
        json_skip_ws(s); if (substr(s, JSON_POS, 1) != ":") { JSON_OK = 0; JSON_OBJECT_DEPTH--; return }
        JSON_POS++; json_parse_value(s); if (!JSON_OK) { JSON_OBJECT_DEPTH--; return }
        json_skip_ws(s); c = substr(s, JSON_POS, 1)
        if (c == "}") { JSON_POS++; JSON_OBJECT_DEPTH--; return }
        if (c != ",") { JSON_OK = 0; JSON_OBJECT_DEPTH--; return }
        JSON_POS++; json_skip_ws(s)
    }
    JSON_OBJECT_DEPTH--
}

function json_parse_value(s, c) {
    json_skip_ws(s); c = substr(s, JSON_POS, 1)
    if (c == "\"") json_parse_string(s)
    else if (c == "{") json_parse_object(s)
    else if (c == "[") json_parse_array(s)
    else if (c == "-" || c ~ /^[0-9]$/) json_parse_number(s)
    else if (substr(s, JSON_POS, 4) == "true") JSON_POS += 4
    else if (substr(s, JSON_POS, 5) == "false") JSON_POS += 5
    else if (substr(s, JSON_POS, 4) == "null") JSON_POS += 4
    else JSON_OK = 0
}

function valid_json(s) {
    if (s == "") return 0
    for (JSON_KEY in json_object_keys) delete json_object_keys[JSON_KEY]
    JSON_OBJECT_DEPTH = 0; JSON_POS = 1; JSON_OK = 1; json_parse_value(s); json_skip_ws(s)
    return JSON_OK && JSON_POS > length(s)
}

function valid_rpc_id(raw) {
    if (raw == "null") return 1
    if (substr(raw, 1, 1) == "\"") return valid_json(raw)
    if (raw !~ /^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$/) return 0
    return valid_json(raw)
}

function raw_kind(raw, i, c) {
    i = ws(raw, 1); c = substr(raw, i, 1)
    if (c == "{") return "object"
    if (c == "[") return "array"
    if (c == "\"") return "string"
    if (c == "-" || c ~ /^[0-9]$/) return "number"
    return "value"
}

function bounded_raw(raw) {
    if (length(raw) <= MAX_CONTEXT_TEXT) return raw
    return "{\"kind\":" json_escape(raw_kind(raw)) ",\"bytes\":" length(raw) ",\"truncated\":true}"
}

function bounded_json_string(value) { return json_escape(substr(value, 1, MAX_CONTEXT_TEXT)) }

function bounded_text_field(name, value, out) {
    out = json_escape(name) ":" bounded_json_string(value)
    if (length(value) > MAX_CONTEXT_TEXT) out = out "," json_escape(name "_truncated") ":true"
    return out
}

function bounded_raw_field(name, value, out) {
    out = json_escape(name) ":" bounded_raw(value)
    if (length(value) > MAX_CONTEXT_TEXT) out = out "," json_escape(name "_truncated") ":true"
    return out
}

function bounded_string_array(raw, i, start, e, count, item, value, list) {
    ARRAY_COUNT = 0; ARRAY_TRUNCATED = 0; list = "["
    if (substr(raw, 1, 1) != "[" || !valid_json(raw)) return list "]"
    i = ws(raw, 2)
    while (i <= length(raw) && substr(raw, i, 1) != "]") {
        start = ws(raw, i); e = value_end(raw, start)
        if (e < start) break
        ARRAY_COUNT++
        if (ARRAY_COUNT <= MAX_CONTEXT_ITEMS) {
            item = substr(raw, start, e - start + 1)
            if (substr(item, 1, 1) == "\"") {
                value = json_decode(item)
                if (length(value) > MAX_CONTEXT_TEXT) value = substr(value, 1, MAX_CONTEXT_TEXT)
                item = json_escape(value)
            } else item = bounded_raw(item)
            if (ARRAY_COUNT > 1) list = list ","
            list = list item
        }
        i = ws(raw, e + 1)
        if (substr(raw, i, 1) == ",") i = ws(raw, i + 1)
        else break
    }
    if (ARRAY_COUNT > MAX_CONTEXT_ITEMS) ARRAY_TRUNCATED = 1
    return list "]"
}

function load_sources(line, id) {
    while ((getline line < source_file) > 0) if (valid_json(line) && persisted_source(line)) {
        object_get(line, "id")
        id = GET_STRING
        if (id in source_json) continue
        source_json[id] = line
        object_get(line, "title"); source_title[id] = GET_STRING
        object_get(line, "reference"); source_reference[id] = GET_STRING
        object_get(line, "source_type"); source_kind[id] = GET_STRING
        object_get(line, "project"); source_project[id] = GET_STRING
        object_get(line, "status"); source_status[id] = GET_STRING
        object_get(line, "uncertainty"); source_uncertainty[id] = GET_STRING
        object_get(line, "notes"); source_notes[id] = GET_STRING
        source_search[id] = tolower(source_title[id] " " source_reference[id] " " source_kind[id] " " source_project[id] " " source_status[id] " " source_uncertainty[id] " " source_notes[id]); sequence++
    }
    close(source_file)
}

function load_nodes(line, id) {
    while ((getline line < node_file) > 0) if (valid_json(line) && persisted_node(line)) {
        object_get(line, "id")
        id = GET_STRING
        if (id in node_json) continue
        node_json[id] = line
        object_get(line, "node_type"); node_type[id] = GET_STRING
        object_get(line, "label"); node_label[id] = GET_STRING
        object_get(line, "source_ids"); node_sources[id] = GET_RAW
        object_get(line, "claim_status"); node_claim_status[id] = GET_STRING
        object_get(line, "confidence"); node_confidence[id] = GET_STRING
        object_get(line, "description"); node_description[id] = GET_STRING
        object_get(line, "reference"); node_reference[id] = GET_STRING
        object_get(line, "status"); node_status[id] = GET_STRING
        object_get(line, "uncertainty"); node_uncertainty[id] = GET_STRING
        node_search[id] = tolower(node_type[id] " " node_label[id] " " line); sequence++
    }
    close(node_file)
}

function load_edges(line, id) {
    while ((getline line < edge_file) > 0) if (valid_json(line) && persisted_edge(line)) {
        object_get(line, "id")
        id = GET_STRING
        if (id in edge_json) continue
        edge_json[id] = line
        object_get(line, "from"); edge_from[id] = GET_STRING
        object_get(line, "to"); edge_to[id] = GET_STRING
        object_get(line, "relation"); edge_relation[id] = GET_STRING
        object_get(line, "source_ids"); edge_sources[id] = (GET_PRESENT ? GET_RAW : "[]")
        object_get(line, "evidence"); edge_has_evidence[id] = GET_PRESENT && GET_RAW != "null"
        sequence++
    }
    close(edge_file)
}

function generated_id_in_use(prefix, candidate) {
    if (prefix == "src") return (candidate in source_json) || (("source-" candidate) in node_json)
    if (prefix == "edge") return candidate in edge_json
    return 0
}

function next_id(prefix, candidate) {
    do { sequence++; candidate = prefix "-" systime() "-" sequence } while (generated_id_in_use(prefix, candidate))
    return candidate
}
function append_record(file, record) { print record >> file; close(file) }
function fail(message) { TOOL_ERROR = message; return 0 }
function required_string(obj, name, label) { object_get(obj, name); if (!GET_PRESENT || substr(GET_RAW, 1, 1) != "\"") return fail(label " requires string argument '" name "'"); return 1 }
function required_nonempty_string(obj, name, label) { if (!required_string(obj, name, label)) return 0; if (GET_STRING ~ /^[[:space:]]*$/) return fail(label " requires a non-empty string argument '" name "'"); return 1 }
function valid_identifier(value, label) { if (value == "" || value ~ /^[[:space:]]*$/) return fail(label " requires a non-empty identifier"); if (length(value) > MAX_IDENTIFIER_TEXT) return fail(label " identifier exceeds " MAX_IDENTIFIER_TEXT " characters"); return 1 }
function valid_source_identifier(value, label) { if (!valid_identifier(value, label)) return 0; if (length(value) > MAX_SOURCE_IDENTIFIER_TEXT) return fail(label " identifier exceeds " MAX_SOURCE_IDENTIFIER_TEXT " characters because its derived Source node id must fit the graph limit"); return 1 }
function optional_string(obj, name, default_value, label) { object_get(obj, name); if (GET_PRESENT && substr(GET_RAW, 1, 1) != "\"") { fail(label " requires string argument '" name "'"); return default_value }; if (GET_PRESENT) return GET_STRING; return default_value }
function optional_nonempty_string(obj, name, default_value, label) { object_get(obj, name); if (!GET_PRESENT) return default_value; if (substr(GET_RAW, 1, 1) != "\"" || GET_STRING ~ /^[[:space:]]*$/) { fail(label " requires a non-empty string argument '" name "'"); return default_value }; return GET_STRING }
function required_raw(obj, name, label) { object_get(obj, name); if (!GET_PRESENT || GET_RAW == "null") return fail(label " requires argument '" name "'"); return GET_RAW }
function array_or_empty(obj, name, label, raw) { object_get(obj, name); raw = (GET_PRESENT ? GET_RAW : "[]"); if (substr(raw, 1, 1) != "[" || !valid_json(raw)) { fail(label " '" name "' must be a valid JSON array"); return "" }; return raw }
function bounded_limit(obj, name, default_value, raw, value) { object_get(obj, name); value = default_value; if (GET_PRESENT && GET_RAW !~ /^[0-9]+$/) { fail("requires a positive integer argument '" name "'"); return default_value }; if (GET_PRESENT) value = GET_RAW + 0; if (GET_PRESENT && value < 1) { fail("requires a positive integer argument '" name "'"); return default_value }; if (value < 1) value = 1; if (value > MAX_CONTEXT_ITEMS) value = MAX_CONTEXT_ITEMS; return value }

function persisted_string(obj, name, nonempty) { object_get(obj, name); return GET_PRESENT && substr(GET_RAW, 1, 1) == "\"" && (!nonempty || GET_STRING !~ /^[[:space:]]*$/) }
function persisted_identifier(obj, name) { object_get(obj, name); return GET_PRESENT && substr(GET_RAW, 1, 1) == "\"" && GET_STRING !~ /^[[:space:]]*$/ && length(GET_STRING) <= MAX_IDENTIFIER_TEXT }
function persisted_source_identifier(obj, name) { object_get(obj, name); return GET_PRESENT && substr(GET_RAW, 1, 1) == "\"" && GET_STRING !~ /^[[:space:]]*$/ && length(GET_STRING) <= MAX_SOURCE_IDENTIFIER_TEXT }
function persisted_optional_string(obj, name) { object_get(obj, name); return !GET_PRESENT || substr(GET_RAW, 1, 1) == "\"" }
function persisted_kind(obj, expected) { object_get(obj, "kind"); return GET_PRESENT && GET_RAW == json_escape(expected) }
function persisted_source_ids(obj, name, raw, i, start, e, item) {
    object_get(obj, name); raw = (GET_PRESENT ? GET_RAW : "")
    if (substr(raw, 1, 1) != "[" || !valid_json(raw)) return 0
    for (item in persisted_source_id_seen) delete persisted_source_id_seen[item]
    i = ws(raw, 2)
    if (substr(raw, i, 1) == "]") return 1
    while (i <= length(raw)) {
        start = ws(raw, i); e = value_end(raw, start)
        if (e < start || substr(raw, start, 1) != "\"") return 0
        item = json_decode(substr(raw, start, e - start + 1))
        if (item == "" || length(item) > MAX_SOURCE_IDENTIFIER_TEXT || !(item in source_json) || (item in persisted_source_id_seen)) return 0
        persisted_source_id_seen[item] = 1
        i = ws(raw, e + 1)
        if (substr(raw, i, 1) == ",") i = ws(raw, i + 1)
        else if (substr(raw, i, 1) == "]") return 1
        else return 0
    }
    return 0
}
function source_ids_match(raw, expected, i, start, e, item) {
    if (substr(raw, 1, 1) != "[" || !valid_json(raw)) return 0
    i = ws(raw, 2); start = i; e = value_end(raw, start)
    if (e < start || substr(raw, start, 1) != "\"") return 0
    item = json_decode(substr(raw, start, e - start + 1)); if (item != expected) return 0
    i = ws(raw, e + 1)
    return substr(raw, i, 1) == "]"
}
function persisted_json_optional(obj, name, raw) { object_get(obj, name); raw = (GET_PRESENT ? GET_RAW : ""); return raw == "" || valid_json(raw) }
function persisted_source(obj) { return persisted_kind(obj, "source") && persisted_source_identifier(obj, "id") && persisted_string(obj, "title", 1) && persisted_string(obj, "reference", 1) && persisted_string(obj, "source_type", 1) && persisted_string(obj, "project", 1) && persisted_string(obj, "status", 1) && persisted_optional_string(obj, "uncertainty") && persisted_optional_string(obj, "notes") }
function persisted_node(obj, id, source_id, node_type_value, claim_status, confidence, source_ids) {
    if (!(persisted_kind(obj, "node") && persisted_identifier(obj, "id") && persisted_string(obj, "node_type", 1) && persisted_string(obj, "label", 1) && persisted_source_ids(obj, "source_ids") && persisted_string(obj, "claim_status", 1) && persisted_string(obj, "confidence", 1) && persisted_optional_string(obj, "description") && persisted_optional_string(obj, "reference") && persisted_optional_string(obj, "status") && persisted_optional_string(obj, "uncertainty"))) return 0
    object_get(obj, "id"); id = GET_STRING
    if (substr(id, 1, 7) != "source-") return 1
    source_id = substr(id, 8)
    if (!(source_id in source_json)) return 1
    object_get(obj, "node_type"); node_type_value = GET_STRING
    object_get(obj, "claim_status"); claim_status = GET_STRING
    object_get(obj, "confidence"); confidence = GET_STRING
    object_get(obj, "source_ids"); source_ids = GET_RAW
    return node_type_value == "Source" && claim_status == "source-material" && confidence == "not-asserted" && source_ids_match(source_ids, source_id)
}
function source_node_matches(id, source_id) {
    return node_type[id] == "Source" && node_claim_status[id] == "source-material" && node_confidence[id] == "not-asserted" && node_label[id] == source_title[source_id] && node_sources_match(node_sources[id], source_id) && node_reference[id] == source_reference[source_id] && node_status[id] == source_status[source_id] && node_uncertainty[id] == source_uncertainty[source_id]
}
function node_sources_match(raw, expected) { return source_ids_match(raw, expected) }
function persisted_edge(obj, id, from, to, relation) {
    if (!(persisted_kind(obj, "edge") && persisted_identifier(obj, "id") && persisted_identifier(obj, "from") && persisted_identifier(obj, "to") && persisted_identifier(obj, "relation") && persisted_source_ids(obj, "source_ids") && persisted_json_optional(obj, "evidence"))) return 0
    object_get(obj, "id"); id = GET_STRING
    object_get(obj, "from"); from = GET_STRING
    object_get(obj, "to"); to = GET_STRING
    object_get(obj, "relation"); relation = GET_STRING
    return (id != "" && from in node_json && to in node_json && relation != "")
}

function validate_source_ids(raw, label, i, start, e, item) {
    if (substr(raw, 1, 1) != "[" || !valid_json(raw)) return fail(label " must be a valid JSON array")
    for (item in validated_source_ids) delete validated_source_ids[item]
    i = ws(raw, 2)
    if (substr(raw, i, 1) == "]") return 1
    while (i <= length(raw)) {
        start = ws(raw, i); e = value_end(raw, start)
        if (e < start || substr(raw, start, 1) != "\"") return fail(label " must contain source id strings")
        item = json_decode(substr(raw, start, e - start + 1))
        if (item == "" || !(item in source_json)) return fail(label " references unknown source: " item)
        if (item in validated_source_ids) return fail(label " contains duplicate source id: " item)
        validated_source_ids[item] = 1
        i = ws(raw, e + 1)
        if (substr(raw, i, 1) == ",") i = ws(raw, i + 1)
        else if (substr(raw, i, 1) == "]") return 1
        else return fail(label " must be an array")
    }
    return fail(label " must be an array")
}

function next_source(used, query, project, best, id) {
    best = ""
    for (id in source_json) if (!(id in used) && (project == "" || source_project[id] == project) && (query == "" || index(source_search[id], tolower(query)) > 0) && (best == "" || id < best)) best = id
    return best
}

function next_related_edge(used, node_id, relation, best, eid, other) {
    best = ""
    for (eid in edge_json) {
        if (eid in used || (relation != "" && edge_relation[eid] != relation)) continue
        if (edge_from[eid] == node_id) other = edge_to[eid]
        else if (edge_to[eid] == node_id) other = edge_from[eid]
        else continue
        if (best == "" || eid < best) best = eid
    }
    return best
}

function next_key(used, values, best, key) {
    best = ""
    for (key in values) if (!(key in used) && (best == "" || key < best)) best = key
    return best
}

function source_summary(id, out) {
    out = "{\"id\":" json_escape(id) ",\"kind\":\"source\"," bounded_text_field("title", source_title[id]) "," bounded_text_field("reference", source_reference[id]) "," bounded_text_field("source_type", source_kind[id]) "," bounded_text_field("project", source_project[id]) "," bounded_text_field("status", source_status[id])
    if (source_uncertainty[id] != "") out = out "," bounded_text_field("uncertainty", source_uncertainty[id])
    if (source_notes[id] != "") out = out "," bounded_text_field("notes", source_notes[id])
    return out "}"
}

function node_summary(id, out, description) {
    source_ids = bounded_string_array(node_sources[id])
    source_count = ARRAY_COUNT; source_truncated = ARRAY_TRUNCATED
    out = "{\"id\":" json_escape(id) ",\"kind\":\"node\"," bounded_text_field("node_type", node_type[id]) "," bounded_text_field("label", node_label[id]) ",\"source_ids\":" source_ids
    if (source_truncated) out = out ",\"source_ids_count\":" source_count ",\"source_ids_truncated\":true"
    out = out "," bounded_text_field("claim_status", node_claim_status[id]) "," bounded_text_field("confidence", node_confidence[id])
    if (node_reference[id] != "") out = out "," bounded_text_field("reference", node_reference[id])
    if (node_status[id] != "") out = out "," bounded_text_field("status", node_status[id])
    if (node_uncertainty[id] != "") out = out "," bounded_text_field("uncertainty", node_uncertainty[id])
    if (node_description[id] != "") out = out "," bounded_text_field("description", node_description[id])
    return out "}"
}

function edge_summary(id) {
    source_ids = bounded_string_array(edge_sources[id])
    source_count = ARRAY_COUNT; source_truncated = ARRAY_TRUNCATED
    out = "{\"id\":" json_escape(id) ",\"kind\":\"edge\"," bounded_text_field("from", edge_from[id]) "," bounded_text_field("to", edge_to[id]) "," bounded_text_field("relation", edge_relation[id]) ",\"source_ids\":" source_ids
    if (source_truncated) out = out ",\"source_ids_count\":" source_count ",\"source_ids_truncated\":true"
    return out ",\"has_evidence\":" (edge_has_evidence[id] ? "true" : "false") "}"
}

function handle_request(line, method, id_present, params) {
    REQUEST_NOTIFICATION = 0
    if (length(line) > MAX_REQUEST_TEXT) { ID_RAW = "null"; rpc_error(-32600, "request exceeds " MAX_REQUEST_TEXT " characters"); return }
    if (!valid_json(line)) { ID_RAW = "null"; rpc_error(-32700, "parse error"); return }
    object_get(line, "id"); REQUEST_NOTIFICATION = !GET_PRESENT
    object_get(line, "jsonrpc")
    if (!GET_PRESENT || GET_RAW != "\"2.0\"") { ID_RAW = "null"; rpc_error(-32600, "request requires jsonrpc 2.0"); return }
    ID_RAW = "null"; object_get(line, "id"); id_present = GET_PRESENT; if (id_present) ID_RAW = GET_RAW
    if (id_present && !valid_rpc_id(ID_RAW)) { ID_RAW = "null"; rpc_error(-32600, "request id must be a string, number, or null"); return }
    REQUEST_NOTIFICATION = !id_present
    object_get(line, "method")
    if (!GET_PRESENT || substr(GET_RAW, 1, 1) != "\"") { if (id_present) rpc_error(-32600, "request requires string method"); return }
    method = GET_STRING
    object_get(line, "params")
    if (GET_PRESENT && substr(GET_RAW, 1, 1) != "{" && substr(GET_RAW, 1, 1) != "[") { if (id_present) rpc_error(-32600, "request params must be an object or array"); return }
    if (method == "notifications/initialized" || method == "notifications/cancelled") return
    if (method == "exit") exit 0
    if (SHUTDOWN_REQUESTED) { if (id_present) rpc_error(-32600, "server is shutting down"); return }
    if (method == "initialize") { rpc_result("{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{\"tools\":{},\"resources\":{\"subscribe\":false,\"listChanged\":false}},\"serverInfo\":{\"name\":\"owlknowledge\",\"version\":\"0.1.0\"}}"); return }
    if (method == "ping") { rpc_result("{}"); return }
    if (method == "tools/list") { rpc_result(tools_json()); return }
    if (method == "resources/list") { rpc_result(resources_json()); return }
    if (method == "resources/read") { object_get(line, "params"); params = (GET_PRESENT ? GET_RAW : "{}"); resource_read(params); return }
    if (method == "tools/call") { object_get(line, "params"); params = (GET_PRESENT ? GET_RAW : "{}"); tool_call(params); return }
    if (method == "shutdown") { SHUTDOWN_REQUESTED = 1; rpc_result("null"); return }
    if (id_present) rpc_error(-32601, "method not found: " method)
}

function rpc_result(result) { if (REQUEST_NOTIFICATION) return; print "{\"jsonrpc\":\"2.0\",\"id\":" ID_RAW ",\"result\":" result "}"; fflush() }
function rpc_error(code, message) { if (REQUEST_NOTIFICATION) return; print "{\"jsonrpc\":\"2.0\",\"id\":" ID_RAW ",\"error\":{\"code\":" code ",\"message\":" json_escape(message) "}}"; fflush() }
function tool_text(message, is_error) { if (REQUEST_NOTIFICATION) return; if (length(message) > MAX_RESPONSE_TEXT) message = "{\"truncated\":true,\"bytes\":" length(message) "}"; print "{\"jsonrpc\":\"2.0\",\"id\":" ID_RAW ",\"result\":{\"content\":[{\"type\":\"text\",\"text\":" json_escape(message) "}]" (is_error ? ",\"isError\":true" : "") "}}"; fflush() }

function tools_json() {
    return "{\"tools\":[" \
      "{\"name\":\"discover\",\"description\":\"Explain the source/derived-graph boundary and route the small public surface. Read-only.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}," \
      "{\"name\":\"register_source\",\"description\":\"Register a source reference without copying, rewriting, or declaring its contents true.\",\"inputSchema\":{\"type\":\"object\",\"required\":[\"title\",\"reference\",\"source_type\"],\"properties\":{\"title\":{\"type\":\"string\"},\"reference\":{\"type\":\"string\"},\"source_type\":{\"type\":\"string\"},\"project\":{\"type\":\"string\"},\"status\":{\"type\":\"string\"},\"uncertainty\":{\"type\":\"string\"},\"notes\":{\"type\":\"string\"},\"source_id\":{\"type\":\"string\"}}}}," \
      "{\"name\":\"search_sources\",\"description\":\"Find source metadata by title, reference, type, project, or uncertainty/status. Results are hard-capped at 20.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{\"query\":{\"type\":\"string\"},\"project\":{\"type\":\"string\"},\"limit\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":20}}}}," \
      "{\"name\":\"rebuild_graph\",\"description\":\"Refresh derived Source nodes without deleting interpreted graph data; source records are never changed.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}," \
      "{\"name\":\"add_node\",\"description\":\"Add an interpreted graph node while retaining source ids, claim status, and uncertainty metadata.\",\"inputSchema\":{\"type\":\"object\",\"required\":[\"node_id\",\"node_type\",\"label\"],\"properties\":{\"node_id\":{\"type\":\"string\"},\"node_type\":{\"type\":\"string\"},\"label\":{\"type\":\"string\"},\"source_ids\":{\"type\":\"array\"},\"description\":{\"type\":\"string\"},\"claim_status\":{\"type\":\"string\"},\"confidence\":{\"type\":\"string\"}}}}," \
      "{\"name\":\"add_edge\",\"description\":\"Add a typed relation such as references, supports, contradicts, derived-from, related-to, or evaluates.\",\"inputSchema\":{\"type\":\"object\",\"required\":[\"from\",\"to\",\"relation\"],\"properties\":{\"from\":{\"type\":\"string\"},\"to\":{\"type\":\"string\"},\"relation\":{\"type\":\"string\"},\"source_ids\":{\"type\":\"array\"},\"evidence\":{},\"edge_id\":{\"type\":\"string\"}}}}," \
      "{\"name\":\"traverse_graph\",\"description\":\"Trace a bounded number of one-hop related nodes and edges back to their source references. Results are hard-capped at 20.\",\"inputSchema\":{\"type\":\"object\",\"required\":[\"node_id\"],\"properties\":{\"node_id\":{\"type\":\"string\"},\"relation\":{\"type\":\"string\"},\"limit\":{\"type\":\"integer\",\"minimum\":1,\"maximum\":20}}}}," \
      "{\"name\":\"export_structure\",\"description\":\"Export node and relation types only, with no source contents, for structure sharing and evolution.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}]}"
}

function resources_json() { return "{\"resources\":[{\"uri\":\"owlknowledge://structure\",\"name\":\"Derived graph structure\",\"description\":\"Node and relation types without source contents.\",\"mimeType\":\"application/json\"}]}" }

function resource_read(params, uri) {
    object_get(params, "uri")
    if (!GET_PRESENT || substr(GET_RAW, 1, 1) != "\"") { rpc_error(-32602, "resources/read requires uri"); return }
    uri = GET_STRING
    if (uri == "owlknowledge://structure") { rpc_result("{\"contents\":[{\"uri\":\"owlknowledge://structure\",\"mimeType\":\"application/json\",\"text\":" json_escape(structure_payload()) "}]}"); return }
    rpc_error(-32001, "unknown resource: " uri)
}

function tool_call(params, name, args) {
    object_get(params, "name")
    if (!GET_PRESENT || substr(GET_RAW, 1, 1) != "\"") { rpc_error(-32602, "tools/call requires name"); return }
    name = GET_STRING; object_get(params, "arguments"); args = (GET_PRESENT ? GET_RAW : "{}")
    if (substr(args, 1, 1) != "{") { rpc_error(-32602, "tool arguments must be an object"); return }
    TOOL_ERROR = ""
    if (name == "discover") discover()
    else if (name == "register_source") register_source(args)
    else if (name == "search_sources") search_sources(args)
    else if (name == "rebuild_graph") rebuild_graph()
    else if (name == "add_node") add_node(args)
    else if (name == "add_edge") add_edge(args)
    else if (name == "traverse_graph") traverse_graph(args)
    else if (name == "export_structure") tool_text(structure_payload())
    else { rpc_error(-32602, "unknown tool: " name); return }
    if (TOOL_ERROR != "") tool_text(TOOL_ERROR, 1)
}

function discover() {
    tool_text("OwlKnowledge keeps source references as the durable material and the graph as an AI-derived, rebuildable interpretation.\n\nRouting:\n- register_source: record a Markdown, PDF, URL, paper, meeting, experiment, code, or other reference without copying or asserting it is true.\n- search_sources: locate materials by metadata.\n- rebuild_graph: regenerate source nodes after changing graph structure; source records are not deleted.\n- add_node: record claims, methods, experiments, evidence, topics, or decision candidates with source ids and uncertainty.\n- add_edge: connect nodes using a small starting vocabulary; contradicts is valid and is never silently merged.\n- traverse_graph: follow relations and return source-linked nodes.\n- export_structure: share only node/relation types, never source contents.\n\nKnowledge is decision material, not a decision or specification. Graph fields are interpretations and may be revised; source uncertainty and contradiction remain visible.")
}

function register_source(args, title, reference, source_type_value, project, status, uncertainty, notes, id, record) {
    if (!required_nonempty_string(args, "title", "register_source")) return; title = GET_STRING
    if (!required_nonempty_string(args, "reference", "register_source")) return; reference = GET_STRING
    if (!required_nonempty_string(args, "source_type", "register_source")) return; source_type_value = GET_STRING
    project = optional_nonempty_string(args, "project", "current", "register_source"); if (TOOL_ERROR != "") return
    status = optional_nonempty_string(args, "status", "unverified", "register_source"); if (TOOL_ERROR != "") return
    uncertainty = optional_string(args, "uncertainty", "", "register_source"); if (TOOL_ERROR != "") return
    notes = optional_string(args, "notes", "", "register_source"); if (TOOL_ERROR != "") return
    id = optional_string(args, "source_id", "", "register_source"); if (TOOL_ERROR != "") return
    if (id == "") id = next_id("src")
    if (!valid_source_identifier(id, "register_source")) return
    if (id in source_json) { fail("source already exists: " id); return }
    if (("source-" id) in node_json) { fail("source node id conflicts with existing graph node: source-" id); return }
    record = "{\"id\":" json_escape(id) ",\"kind\":\"source\",\"title\":" json_escape(title) ",\"reference\":" json_escape(reference) ",\"source_type\":" json_escape(source_type_value) ",\"project\":" json_escape(project) ",\"status\":" json_escape(status)
    if (uncertainty != "") record = record ",\"uncertainty\":" json_escape(uncertainty)
    if (notes != "") record = record ",\"notes\":" json_escape(notes)
    record = record "}"
    append_record(source_file, record); source_json[id] = record; source_title[id] = title; source_reference[id] = reference; source_kind[id] = source_type_value; source_project[id] = project; source_status[id] = status; source_uncertainty[id] = uncertainty; source_notes[id] = notes; source_search[id] = tolower(title " " reference " " source_type_value " " project " " status " " uncertainty " " notes)
    tool_text("Registered source reference " id ". Its contents remain outside the derived graph.\n" source_summary(id))
}

function search_sources(args, query, project, limit, id, count, list, truncated) {
    query = optional_string(args, "query", "", "search_sources"); if (TOOL_ERROR != "") return
    project = optional_string(args, "project", "", "search_sources"); if (TOOL_ERROR != "") return
    limit = bounded_limit(args, "limit", MAX_CONTEXT_ITEMS); if (TOOL_ERROR != "") return
    for (id in source_used) delete source_used[id]
    list = "["; count = 0
    while (count < limit && (id = next_source(source_used, query, project)) != "") { source_used[id] = 1; if (count > 0) list = list ","; list = list source_summary(id); count++ }
    truncated = (next_source(source_used, query, project) != "")
    tool_text("{\"count\":" count ",\"truncated\":" (truncated ? "true" : "false") ",\"sources\":" list "]}")
}

function add_node(args, id, node_type_value, label, source_ids, description, claim_status, confidence, record) {
    if (!required_nonempty_string(args, "node_id", "add_node")) return; id = GET_STRING
    if (!valid_identifier(id, "add_node")) return
    if (is_reserved_source_node_id(id)) { fail("node id is reserved for a Source node: " id); return }
    if (id in node_json) { fail("node already exists: " id); return }
    if (!required_nonempty_string(args, "node_type", "add_node")) return; node_type_value = GET_STRING
    if (!required_nonempty_string(args, "label", "add_node")) return; label = GET_STRING
    object_get(args, "source_ids"); source_ids = (GET_PRESENT ? GET_RAW : "[]"); if (substr(source_ids, 1, 1) != "[") { fail("add_node source_ids must be an array"); return }
    if (!validate_source_ids(source_ids, "add_node source_ids")) return
    description = optional_string(args, "description", "", "add_node"); if (TOOL_ERROR != "") return
    claim_status = optional_nonempty_string(args, "claim_status", "uncertain", "add_node"); if (TOOL_ERROR != "") return
    confidence = optional_nonempty_string(args, "confidence", "unassessed", "add_node"); if (TOOL_ERROR != "") return
    record = "{\"id\":" json_escape(id) ",\"kind\":\"node\",\"node_type\":" json_escape(node_type_value) ",\"label\":" json_escape(label) ",\"source_ids\":" source_ids ",\"claim_status\":" json_escape(claim_status) ",\"confidence\":" json_escape(confidence)
    if (description != "") record = record ",\"description\":" json_escape(description)
    record = record "}"
    append_record(node_file, record); node_json[id] = record; node_type[id] = node_type_value; node_label[id] = label; node_sources[id] = source_ids; node_claim_status[id] = claim_status; node_confidence[id] = confidence; node_description[id] = description; node_reference[id] = ""; node_status[id] = ""; node_uncertainty[id] = ""; node_search[id] = tolower(node_type_value " " label " " record)
    tool_text("Added derived graph node " id ".\n" node_summary(id))
}

function add_edge(args, from, to, relation, source_ids, evidence, id, record) {
    if (!required_nonempty_string(args, "from", "add_edge")) return; from = GET_STRING
    if (!valid_identifier(from, "add_edge")) return
    if (!required_nonempty_string(args, "to", "add_edge")) return; to = GET_STRING
    if (!valid_identifier(to, "add_edge")) return
    if (!(from in node_json) || !(to in node_json)) { fail("add_edge requires existing from and to nodes"); return }
    if (!required_nonempty_string(args, "relation", "add_edge")) return; relation = GET_STRING
    if (!valid_identifier(relation, "add_edge")) return
    source_ids = array_or_empty(args, "source_ids", "add_edge"); if (!source_ids) return
    if (!validate_source_ids(source_ids, "add_edge source_ids")) return
    object_get(args, "evidence"); evidence = (GET_PRESENT ? GET_RAW : "null")
    if (evidence != "null" && !valid_json(evidence)) { fail("add_edge evidence must be valid JSON"); return }
    id = optional_string(args, "edge_id", "", "add_edge"); if (TOOL_ERROR != "") return
    if (id == "") id = next_id("edge")
    if (!valid_identifier(id, "add_edge")) return
    if (id in edge_json) { fail("edge already exists: " id); return }
    record = "{\"id\":" json_escape(id) ",\"kind\":\"edge\",\"from\":" json_escape(from) ",\"to\":" json_escape(to) ",\"relation\":" json_escape(relation) ",\"source_ids\":" source_ids
    if (evidence != "null") record = record ",\"evidence\":" evidence
    record = record "}"
    append_record(edge_file, record); edge_json[id] = record; edge_from[id] = from; edge_to[id] = to; edge_relation[id] = relation; edge_sources[id] = source_ids; edge_has_evidence[id] = (evidence != "null")
    tool_text("Added derived relation " id ".\n" edge_summary(id))
}

function rebuild_graph(id, node_id, record, count) {
    for (id in rebuild_used) delete rebuild_used[id]
    while ((id = next_source(rebuild_used, "", "")) != "") {
        rebuild_used[id] = 1
        node_id = "source-" id
        if ((node_id in node_json) && !source_node_matches(node_id, id)) {
            fail("cannot rebuild source node; id conflicts with existing graph node: " node_id)
            return
        }
    }
    count = 0
    for (id in rebuild_used) delete rebuild_used[id]
    while ((id = next_source(rebuild_used, "", "")) != "") {
        rebuild_used[id] = 1
        node_id = "source-" id
        record = "{\"id\":" json_escape(node_id) ",\"kind\":\"node\",\"node_type\":\"Source\",\"label\":" json_escape(source_title[id]) ",\"source_ids\":[" json_escape(id) "],\"reference\":" json_escape(source_reference[id]) ",\"claim_status\":\"source-material\",\"confidence\":\"not-asserted\",\"status\":" json_escape(source_status[id])
        if (source_uncertainty[id] != "") record = record ",\"uncertainty\":" json_escape(source_uncertainty[id])
        record = record "}"
        if (!(node_id in node_json) || !source_node_matches(node_id, id)) append_record(node_file, record)
        node_json[node_id] = record; node_type[node_id] = "Source"; node_label[node_id] = source_title[id]; node_sources[node_id] = "[" json_escape(id) "]"; node_claim_status[node_id] = "source-material"; node_confidence[node_id] = "not-asserted"; node_description[node_id] = ""; node_reference[node_id] = source_reference[id]; node_status[node_id] = source_status[id]; node_uncertainty[node_id] = source_uncertainty[id]; node_search[node_id] = tolower("source " source_title[id] " " source_reference[id]); count++
    }
    tool_text("{\"rebuilt\":true,\"source_count\":" length_source() ",\"source_nodes\":" count ",\"preserved_derived_graph\":true,\"graph_note\":\"Source nodes were refreshed; interpreted nodes and relations remain intact.\"}")
}

function is_reserved_source_node_id(id, source_id) {
    for (source_id in source_json) if (id == "source-" source_id) return 1
    return 0
}

function length_source(id, n) { n = 0; for (id in source_json) n++; return n }

function traverse_graph(args, id, relation, eid, list_edges, list_nodes, count_edges, count_nodes, other, limit, truncated) {
    if (!required_nonempty_string(args, "node_id", "traverse_graph")) return; id = GET_STRING
    if (!valid_identifier(id, "traverse_graph")) return
    if (!(id in node_json)) { fail("unknown graph node: " id); return }
    relation = optional_string(args, "relation", "", "traverse_graph"); if (TOOL_ERROR != "") return
    limit = bounded_limit(args, "limit", MAX_CONTEXT_ITEMS); if (TOOL_ERROR != "") return
    for (eid in traverse_used) delete traverse_used[eid]
    list_edges = "["; list_nodes = "["; count_edges = 0; count_nodes = 0; truncated = 0
    while (count_edges < limit && (eid = next_related_edge(traverse_used, id, relation)) != "") {
        traverse_used[eid] = 1
        if (edge_from[eid] == id) other = edge_to[eid]; else other = edge_from[eid]
        if (count_edges > 0) list_edges = list_edges ","; list_edges = list_edges edge_summary(eid); count_edges++
        if (count_nodes > 0) list_nodes = list_nodes ","; list_nodes = list_nodes node_summary(other); count_nodes++
    }
    if (next_related_edge(traverse_used, id, relation) != "") truncated = 1
    tool_text("{\"node\":" node_summary(id) ",\"edges\":" list_edges "] ,\"related_nodes\":" list_nodes "] ,\"truncated\":" (truncated ? "true" : "false") "}")
}

function structure_payload(id, types, relations, type_list, relation_list, type_count, relation_count, e, t, r, out) {
    for (id in types) delete types[id]
    for (id in relations) delete relations[id]
    for (id in type_list) delete type_list[id]
    for (id in relation_list) delete relation_list[id]
    for (id in structure_type_used) delete structure_type_used[id]
    for (id in structure_relation_used) delete structure_relation_used[id]
    type_count = 0; relation_count = 0
    for (id in node_type) if (!(node_type[id] in types)) { types[node_type[id]] = 1; type_list[++type_count] = node_type[id] }
    for (id in edge_relation) if (!(edge_relation[id] in relations)) { relations[edge_relation[id]] = 1; relation_list[++relation_count] = edge_relation[id] }
    out = "{\"node_types\":["; t = 0; while (t < MAX_CONTEXT_ITEMS && (id = next_key(structure_type_used, types)) != "") { structure_type_used[id] = 1; if (t++ > 0) out = out ","; out = out bounded_json_string(id) }; out = out "],\"node_type_count\":" type_count ",\"node_types_truncated\":" (type_count > MAX_CONTEXT_ITEMS ? "true" : "false") ",\"relations\":["; r = 0; while (r < MAX_CONTEXT_ITEMS && (id = next_key(structure_relation_used, relations)) != "") { structure_relation_used[id] = 1; if (r++ > 0) out = out ","; out = out bounded_json_string(id) }; return out "],\"relation_count\":" relation_count ",\"relations_truncated\":" (relation_count > MAX_CONTEXT_ITEMS ? "true" : "false") "}"
}
