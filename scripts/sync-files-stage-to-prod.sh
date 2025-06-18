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

# Confirmation prompt to prevent accidental sync to production
read -p "WARNING: This will overwrite production wp-content files with staging wp-content files. Are you sure you want to sync wp-content files from stage to production? (y/N) " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
  echo "Sync cancelled."
  exit 1
fi

# Verify required variables
: ${STAGE_SSH:? "STAGE_SSH is not set in .env"}
: ${STAGE_WP_PATH:? "STAGE_WP_PATH is not set in .env"}
: ${PROD_SSH:? "PROD_SSH is not set in .env"}
: ${PROD_WP_PATH:? "PROD_WP_PATH is not set in .env"}

# Sync files
echo "Syncing files from $STAGE_WP_PATH to $PROD_WP_PATH on $PROD_SSH..."
if [ "$STAGE_SSH" = "$PROD_SSH" ]; then
  # Same server: use local rsync on the server
  ssh "$PROD_SSH" "rsync -avz --progress --delete --exclude 'wp-config.php' \"$STAGE_WP_PATH/\" \"$PROD_WP_PATH/\"" || {
    echo "File sync failed!"
    exit 1
  }
else
  # Different servers: use rsync over SSH
  ssh "$PROD_SSH" "rsync -avz --progress --delete --exclude 'wp-config.php' $STAGE_SSH:$STAGE_WP_PATH/ $PROD_WP_PATH/" || {
    echo "File sync failed!"
    exit 1
  }
fi

echo "Sync wp-content files from stage to production complete!"
