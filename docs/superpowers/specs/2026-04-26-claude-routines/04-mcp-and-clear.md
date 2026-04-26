# MCP connections semantics

Three behaviors users need to know, only two of which are obvious.

## Sending `mcp_connections`

| Frontmatter field | What `claude-routines` sends | API behavior |
|---|---|---|
| Field absent | (omit `mcp_connections` from update body) | Live connections preserved. |
| Field present, non-empty: `[{...}, ...]` | `mcp_connections: [{...}, ...]` | **Replace** with the new list. |
| Field present, empty: `[]` | `clear_mcp_connections: true` | **Wipe** all connections. |

The trap: sending `mcp_connections: []` directly to the API is a **no-op** (the field is silently treated as "not provided"). To clear, you need the separate `clear_mcp_connections: true` flag. `claude-routines` translates the user's intent (an empty YAML list) into the right flag automatically.

## No auto-attach at API layer

The web UI's "Add connector" dropdown auto-populates with currently-connected account-level connectors when creating a new routine — which made it look like Excalidraw "auto-attaches." It doesn't, at the API layer. Direct API creates with `mcp_connections` omitted store empty. This is good news: our default frontmatter doesn't need to specify `mcp_connections: []` as an opt-out.

## Custom MCP servers

The API does not validate `connector_uuid`. Any v4 UUID + arbitrary `name` + `url` is accepted and stored. So users can attach custom MCPs (a self-hosted Telegram MCP, internal company MCPs, etc.) directly via frontmatter without going through the web UI's "Connect" flow.

**Caveat (untested):** the cloud session's behavior with an unreachable MCP URL is unknown. The management API stores whatever you send; runtime might fail to connect, refuse to start, or skip the bad connector. README warns: validation surfaces in the session, not at deploy time.

## Round-trip on `pull`

`pull` writes `mcp_connections` exactly as the API returns it, including the `connector_uuid` field. This makes round-tripping (pull → edit prompt → push) safe: the existing connector configuration is preserved verbatim.

If a user wants to remove a connector, they delete the entry from the array. If they want to remove ALL connectors, they leave the array empty (`mcp_connections: []`). Our update flow translates this to `clear_mcp_connections: true`.
