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

# Verify required variables
: ${LOCAL_WP_PATH:? "LOCAL_WP_PATH is not set in .env"}

# Define backup directory and timestamp
BACKUP_DIR="$PARENT_DIR/backups/local/files"
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/files-$TIMESTAMP.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Create files backup
echo "Backing up local files..."
tar -czf $BACKUP_FILE -C $LOCAL_WP_PATH .

if [ $? -eq 0 ]; then
  echo "Files backup created: $BACKUP_FILE"
else
  echo "Error: Files backup failed!"
  rm -f $BACKUP_FILE
  exit 1
fi
