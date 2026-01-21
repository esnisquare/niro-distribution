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

# Load .env.custom if it exists
if [ -f ".env.custom" ]; then
  echo "Loading .env.custom"
  set -a
  source .env.custom
  set +a
fi

# Check if NIRO_LOCAL_WORKSPACE is set and not empty
if [ -n "${NIRO_LOCAL_WORKSPACE:-}" ]; then
  # Variable is already set - ensure it's stored in .env.custom
  if [ ! -f ".env.custom" ] || ! grep -q "^NIRO_LOCAL_WORKSPACE=" .env.custom 2>/dev/null; then
    # Create or append to .env.custom if it doesn't already contain the variable
    if [ ! -f ".env.custom" ]; then
      echo "NIRO_LOCAL_WORKSPACE=$NIRO_LOCAL_WORKSPACE" > .env.custom
    else
      echo "NIRO_LOCAL_WORKSPACE=$NIRO_LOCAL_WORKSPACE" >> .env.custom
    fi
    echo "Stored existing NIRO_LOCAL_WORKSPACE=$NIRO_LOCAL_WORKSPACE in .env.custom"
  fi
else
  # Variable is not set - prompt user
  echo
  echo "NIRO_LOCAL_WORKSPACE is not set."
  echo "This should be the absolute path to the workspace directory where your projects are cloned."
  echo "Example: /home/user/projects or /Users/username/workspace"
  echo
  
  while true; do
    read -p "Please enter the absolute path to your workspace: " workspace_path < /dev/tty
    
    # Remove trailing slashes
    workspace_path=$(echo "$workspace_path" | sed 's:/*$::')
    
    # Check if it's an absolute path
    if [[ "$workspace_path" != /* ]]; then
      echo "Error: Please provide an absolute path (must start with /)"
      continue
    fi
    
    # Check if the directory exists
    if [ ! -d "$workspace_path" ]; then
      read -p "Directory does not exist. Create it? (y/n): " create_dir < /dev/tty
      if [[ "$create_dir" =~ ^[Yy]$ ]]; then
        mkdir -p "$workspace_path"
        if [ $? -eq 0 ]; then
          echo "Created directory: $workspace_path"
          break
        else
          echo "Error: Failed to create directory. Please try again."
          continue
        fi
      else
        echo "Please enter a valid existing directory path."
        continue
      fi
    else
      break
    fi
  done
  
  # Create .env.custom file with the workspace path
  echo "NIRO_LOCAL_WORKSPACE=$workspace_path" > .env.custom
  echo "Created .env.custom with NIRO_LOCAL_WORKSPACE=$workspace_path"
  
  # Load the new .env.custom
  set -a
  source .env.custom
  set +a
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
