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

# Confirmation prompt to prevent accidental sync to stage
read -p "WARNING: This will overwrite staging wp-content files with local wp-content files. Are you sure you want to sync wp-content files from local to stage? (y/N) " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
  echo "Sync cancelled."
  exit 1
fi

# Verify required variables
: ${STAGE_SSH:? "STAGE_SSH is not set in .env"}
: ${STAGE_WP_PATH:? "STAGE_WP_PATH is not set in .env"}

# Sync files
echo "Syncing files from ./wp-content to $STAGE_SSH:$STAGE_WP_PATH..."
rsync -avz --progress --delete --exclude 'wp-config.php' "./wp-content/" "$STAGE_SSH:$STAGE_WP_PATH/" || {
  echo "File sync failed!"
  exit 1
}

echo "Sync wp-content files from local to stage complete!"
