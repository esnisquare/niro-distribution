#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/niro}"

echo "Installing Niro into: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# If user ran curl|bash, we need to fetch the repo files:
# We download docker-compose.yml + .env.example from the same repo that hosts this script.
REPO_RAW_BASE="${REPO_RAW_BASE:https://raw.githubusercontent.com/esnisquare/niro-distribution/main}"

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

# Load .env to check for existing values
if [ -f ".env" ]; then
  set -a
  source .env
  set +a
fi

# Function to set or update a variable in .env file
set_env_var() {
  local var_name="$1"
  local var_value="$2"
  
  # Escape pipe character and backslashes in the value for sed (using | as delimiter)
  local escaped_value=$(printf '%s\n' "$var_value" | sed 's/|/\\|/g; s/\\/\\\\/g')
  
  if grep -q "^${var_name}=" .env 2>/dev/null; then
    # Variable exists - update it
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS uses different sed syntax
      sed -i '' "s|^${var_name}=.*|${var_name}=${escaped_value}|" .env
    else
      # Linux sed syntax
      sed -i "s|^${var_name}=.*|${var_name}=${escaped_value}|" .env
    fi
    echo "Updated ${var_name} in .env"
  else
    # Variable doesn't exist - append it
    echo "${var_name}=${var_value}" >> .env
    echo "Added ${var_name} to .env"
  fi
}

# Check if NIRO_LOCAL_WORKSPACE is set and not empty
if [ -n "${NIRO_LOCAL_WORKSPACE:-}" ]; then
  # Variable is already set - ensure it's stored in .env
  set_env_var "NIRO_LOCAL_WORKSPACE" "$NIRO_LOCAL_WORKSPACE"
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
  
  # Store the workspace path in .env
  set_env_var "NIRO_LOCAL_WORKSPACE" "$workspace_path"
  
  # Reload .env to make the variable available
  set -a
  source .env
  set +a
  echo
fi

# Check if NIRO_API_KEY is set and not empty
if [ -n "${NIRO_API_KEY:-}" ]; then
  # Variable is already set - ensure it's stored in .env
  set_env_var "NIRO_API_KEY" "$NIRO_API_KEY"
else
  # Variable is not set - prompt user
  echo
  echo "NIRO_API_KEY is not set."
  echo "This API key is required to authenticate with the Niro services."
  echo
  
  while true; do
    read -p "Please enter your NIRO_API_KEY: " api_key < /dev/tty
    
    # Remove leading/trailing whitespace
    api_key=$(echo "$api_key" | xargs)
    
    # Check if it's not empty
    if [ -z "$api_key" ]; then
      echo "Error: API key cannot be empty. Please try again."
      continue
    fi
    
    # Basic validation - check if it looks like a reasonable API key (at least 8 characters)
    if [ ${#api_key} -lt 8 ]; then
      read -p "API key seems too short. Continue anyway? (y/n): " confirm < /dev/tty
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        continue
      fi
    fi
    
    break
  done
  
  # Store the API key in .env
  set_env_var "NIRO_API_KEY" "$api_key"
  
  # Reload .env to make the variable available
  set -a
  source .env
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
