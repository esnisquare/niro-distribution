#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/niro}"

echo "Installing Niro into: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# If user ran curl|bash, we need to fetch the repo files:
# We download docker-compose.yml + .env.example from the same repo that hosts this script.
REPO_RAW_BASE="${REPO_RAW_BASE:-https://raw.githubusercontent.com/esnisquare/niro-distribution/main}"

fetch_if_missing() {
  local file="$1"
  echo "$file"
  if [ ! -f "$file" ]; then
    echo "Downloading $file"
    curl -fsSL "$REPO_RAW_BASE/$file" -o "$file"
  fi
}

fetch_if_missing "docker-compose.yml"
fetch_if_missing ".env.example"

if [ ! -f ".env" ]; then
  echo "Creating .env from .env.example"
  cp .env.example .env
  echo
  echo "IMPORTANT: Please edit $INSTALL_DIR/.env and change passwords (MONGO_ROOT_PASSWORD, NEO4J_PASSWORD)."
  echo
fi

mkdir -p ./data/git-repos

# Check docker
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker is not installed."
  exit 1
fi

# Compose v2 check
if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker compose is not available. Install Docker Desktop or docker-compose v2."
  exit 1
fi

echo "Pulling images..."
docker compose pull

echo "Starting services..."
docker compose up -d

echo
echo "Niro should be available at: http://localhost:8089"
echo "ai-orchestrator: http://localhost:8095"
echo

# Try to open browser (best effort)
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "http://localhost:8089" >/dev/null 2>&1 || true
elif command -v open >/dev/null 2>&1; then
  open "http://localhost:8089" >/dev/null 2>&1 || true
fi
