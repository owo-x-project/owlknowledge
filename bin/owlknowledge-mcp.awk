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
    for (byte_index = 0; byte_index <= 255; byte_index++) UTF8_BYTE[sprintf("%c", byte_index)] = byte_index
    load_sources(); load_nodes(); load_edges()
}

{ if ($0 !~ /^[[:space:]]*$/) handle_request($0) }




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
