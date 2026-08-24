# OwlKnowledge

## Project overview

OwlKnowledge is a small, standalone MCP server for organizing source references into a navigable knowledge graph. Sources remain durable material, while graph nodes and relations are revisable interpretations.

## Concept

OwlKnowledge keeps the source reference as the foundation and records AI-derived Nodes and Edges around it. Claims remain traceable to sources, and uncertainty or contradiction is preserved instead of being turned into a decision.

## Scenarios it solves

- Find relevant evidence across meeting notes, papers, experiments, code, and external references.
- Trace which sources support, contradict, or relate to a claim or hypothesis.
- Rebuild and improve the derived graph without destroying the underlying source material.

## Installation

Install with APM:

```sh
apm install owo-x-project/owlknowledge --target codex,claude
```

Run from source:

```sh
git clone https://github.com/owo-x-project/owlknowledge.git
cd owlknowledge
./bin/owlknowledge-mcp
```

## License

MIT License. See [LICENSE](LICENSE).
