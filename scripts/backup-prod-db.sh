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

# Set default values for production variables (if not set in .env)
PROD_DB_NAME="${PROD_DB_NAME:-wordpress}"
PROD_DB_ROOT_PASSWORD="${PROD_DB_ROOT_PASSWORD:-wordpress}"

# Verify required variables
: ${PROD_SSH:? "PROD_SSH is not set in .env"}
: ${PROD_DB_CONTAINER:? "PROD_DB_CONTAINER is not set in .env"}
: ${PROD_DB_NAME:? "PROD_DB_NAME is not set in .env"}
: ${PROD_DB_ROOT_PASSWORD:? "PROD_DB_ROOT_PASSWORD is not set in .env"}

# Define backup directory and timestamp
BACKUP_DIR="$PARENT_DIR/backups/prod/db"
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/$PROD_DB_NAME-$TIMESTAMP.sql.gz"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Create database backup
echo "Backing up production database..."
ssh $PROD_SSH "docker exec $PROD_DB_CONTAINER mysqldump -uroot -p'$PROD_DB_ROOT_PASSWORD' $PROD_DB_NAME | gzip" > $BACKUP_FILE

if [ $? -eq 0 ]; then
  echo "Database backup created: $BACKUP_FILE"
else
  echo "Error: Database backup failed!"
  rm -f $BACKUP_FILE
  exit 1
fi
