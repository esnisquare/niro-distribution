# Niro – Local Distribution (Docker)

This repository provides a **one-command installer** to run the Niro platform locally using Docker Compose.

It pulls prebuilt images (no source code) and starts all required services:
- Frontend (UI)
- AI Orchestrator
- AST Parser
- MongoDB
- Redis
- Neo4j
- Qdrant

---

## Prerequisites

You must have the following installed:

- **Docker** (20+)
- **Docker Compose v2**

Verify:
```bash
docker --version
docker compose version
```

---

## Quick Install (Recommended)

Run this command in a terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/esnisquare/niro-distribution/main/install.sh | bash
```

This will:
1. Create a directory at `~/niro`
2. Download `docker-compose.yml` and `.env.example`
3. Create `.env` if it does not exist
4. Pull all Docker images
5. Start the full Niro stack

After startup, open:

**http://localhost:8089**

---

## Configuration (`.env`)

On first install, a file is created at:

```
~/niro/.env
```

You may edit this file **before or after** startup.

Important variables include:

```env
# Image versions
AI_ORCHESTRATOR_TAG=latest
AST_PARSER_TAG=latest
FRONTEND_TAG=latest

# Ports
AIO_SERVER_PORT=8095
AST_PARSER_PORT=8210

# MongoDB
MONGO_ROOT_USERNAME=niro
MONGO_ROOT_PASSWORD=change_me
MONGODB_AIO_URI=mongodb://niro:change_me@mongodb:27017/ai?authSource=admin&retryWrites=false

# Neo4j
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=change_me
NEO4J_URI=bolt://neo4j:7687
```

**Change default passwords** if you are running this beyond local testing.

---

## Important: Password Changes & Volumes

MongoDB and Neo4j **store credentials inside Docker volumes**.

If you change passwords in `.env` **after the first run**, you must reset volumes:

```bash
docker compose down -v
docker compose up -d
```

If you do not do this, authentication will fail.

This is expected Docker behaviour, not a bug.

---

## Stopping Niro

```bash
docker compose down
```

To remove all data:
```bash
docker compose down -v
```

---

## Re-running the Installer

You can safely re-run the installer at any time:

```bash
./install.sh
```

---

## Support

If something fails to start:
1. Check `docker compose logs`
2. Verify `.env` values
3. Reset volumes if credentials were changed

For issues, contact the Niro team.
