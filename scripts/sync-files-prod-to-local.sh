#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the parent directory of the script
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables from .env file in the parent directory
if [ -f "$PARENT_DIR/.env" ]; then
  source "$PARENT_DIR/.env"
else
  echo "Error: .env file not found in $PARENT_DIR!"
  exit 1
fi

# Confirmation prompt to prevent accidental sync to local
read -p "WARNING: This will overwrite local wp-content files with production wp-content files. Are you sure you want to sync wp-content files from production to local? (y/N) " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
  echo "Sync cancelled."
  exit 1
fi

# Verify required variables
: ${PROD_SSH:? "PROD_SSH is not set in .env"}
: ${PROD_WP_PATH:? "PROD_WP_PATH is not set in .env"}

# Sync files
echo "Syncing files from $PROD_SSH:$PROD_WP_PATH to ./wp-content..."
rsync -avz --progress --delete --exclude 'wp-config.php' "$PROD_SSH:$PROD_WP_PATH/" "./wp-content/" || {
  echo "File sync failed!"
  exit 1
}

echo "Sync wp-content files from production to local complete!"
