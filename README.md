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
4. **Prompt you for configuration** (see below)
5. Pull all Docker images
6. Start the full Niro stack

After startup, open:

**http://localhost:8089**

### Required Configuration

During installation, you will be prompted for:

#### 1. **Workspace Directory** (`NIRO_LOCAL_WORKSPACE`)
- **What it is**: The absolute path to the directory where your projects/source code are stored
- **Example**: `/home/username/projects` or `/Users/username/workspace`
- **Purpose**: Niro will scan this directory to analyze your projects
- **Where stored**: Saved in `~/niro/.env`

#### 2. **NIRO API Key** (`NIRO_API_KEY`)
- **What it is**: Authentication key required for Niro services
- **Purpose**: Authenticates requests to AI services and project analysis
- **Where stored**: Saved in `~/niro/.env`

---

## Starting Niro Again

After the initial installation, you can start/restart Niro using any of these methods:

### Option 1: Using Docker Compose directly
```bash
cd ~/niro
docker compose up -d
```

### Option 2: Re-run the installer
```bash
cd ~/niro
./install.sh
```

---

## Configuration (`.env`)

Configuration is stored in:

```
~/niro/.env
```

**Key Settings:**
- `NIRO_LOCAL_WORKSPACE`: Path to your workspace directory
- `NIRO_API_KEY`: Your Niro API key
- Database passwords and other service configurations

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

## Updating Configuration

To change your workspace directory or API key:

1. **Edit the configuration file**:
   ```bash
   cd ~/niro
   nano .env  # or use your preferred editor
   ```

2. **Restart the services**:
   ```bash
   docker compose restart
   ```

---

## Support

If something fails to start:
1. Check `docker compose logs`
2. Verify `.env` values
3. Reset volumes if credentials were changed

For issues, contact the Niro team.
