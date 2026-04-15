# Niro MCP Server – Setup Guide

Niro exposes an [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) server that lets AI coding assistants query your project's code graph, semantic search, and analysis directly from the editor.

> **Important**: The MCP server only works for projects that have been indexed by Niro. If a project has not been onboarded and analysed through the Niro UI, the MCP server will not have any context for it.

---

## Prerequisites

- Niro stack is running locally (see [README.md](README.md))
- The project you want to use has been indexed in Niro
- **Node.js** (18+) installed

You will need the following values (available from the Niro UI or your `.env`):

| Variable | Description |
|---|---|
| `NIRO_API_KEY` | Your Niro API key |
| `NIRO_PROJECT_ID` | The Niro project ID for the specific project you are working on |
| `NIRO_API_URL` | AI Assistant URL (default: `http://localhost:8098`) |

---

## Claude Code

Add the MCP server **from the root of the project** you want to use it with:

```bash
cd /path/to/your/project

claude mcp add --transport stdio niro \
    --env NIRO_API_KEY=<your-niro-api-key> \
    --env NIRO_PROJECT_ID=<your-niro-project-id> \
    --env NIRO_API_URL=http://localhost:8098 \
    -- npx -y @niroai/mcp-server
```

This writes the configuration into `.claude/settings.local.json` inside the project directory, scoping it to that project only.

---

## Cursor

1. Open your project in Cursor
2. Go to **Settings > MCP Servers** (or create/edit `.cursor/mcp.json` in the project root)
3. Add the following configuration:

```json
{
  "mcpServers": {
    "niro": {
      "command": "npx",
      "args": ["-y", "@niroai/mcp-server"],
      "transport": "stdio",
      "env": {
        "NIRO_API_KEY": "<your-niro-api-key>",
        "NIRO_PROJECT_ID": "<your-niro-project-id>",
        "NIRO_API_URL": "http://localhost:8098"
      }
    }
  }
}
```

Place this file in the project directory so the server is scoped to that project.

---

## Other MCP-Compatible Editors

Any editor or AI coding tool that supports the [Model Context Protocol](https://modelcontextprotocol.io/) can connect to the Niro MCP server using **stdio** transport.

The generic configuration is:

| Field | Value |
|---|---|
| **Command** | `npx -y @niroai/mcp-server` |
| **Transport** | `stdio` |
| **Environment variables** | `NIRO_API_KEY`, `NIRO_PROJECT_ID`, `NIRO_API_URL` |

Refer to your editor's MCP documentation for the exact configuration format.

---

## Per-Project Setup

Each project you work on will have a **different `NIRO_PROJECT_ID`**. You must configure the MCP server separately for each project directory. Do not add this as a global/user-level configuration — it will not work correctly across projects.

To find your project ID, open the project in the Niro UI and copy the ID from the project settings or URL.

---

## Troubleshooting

- **No results / empty responses** – Verify the project has been indexed in Niro. The MCP server has no context for un-indexed projects.
- **Connection refused** – Ensure the Niro stack is running (`docker compose up -d` from `~/niro`).
- **Authentication errors** – Double-check your `NIRO_API_KEY`.
