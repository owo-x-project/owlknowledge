# Persistence, reload validation, and storage-side query helpers for OwlKnowledge.

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
