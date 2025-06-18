#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found!"
  exit 1
fi

# Verify required variables
: ${REMOTE_SSH:? "REMOTE_SSH is not set in .env"}
: ${REMOTE_DB_CONTAINER:? "REMOTE_DB_CONTAINER is not set in .env"}
: ${REMOTE_WP_PATH:? "REMOTE_WP_PATH is not set in .env"}
: ${LOCAL_WP_CONTAINER:? "LOCAL_WP_CONTAINER is not set in .env"}
: ${LOCAL_DB_CONTAINER:? "LOCAL_DB_CONTAINER is not set in .env"}
: ${LOCAL_WP_PATH:? "LOCAL_WP_PATH is not set in .env"}
: ${PROD_URL:? "PROD_URL is not set in .env"}
: ${LOCAL_URL:? "LOCAL_URL is not set in .env"}
: ${REMOTE_DB_NAME:? "REMOTE_DB_NAME is not set in .env"}
: ${REMOTE_DB_ROOT_PASS:? "REMOTE_DB_ROOT_PASS is not set in .env"}
: ${REMOTE_DB_USER:? "REMOTE_DB_USER is not set in .env"}
: ${REMOTE_DB_PASS:? "REMOTE_DB_PASS is not set in .env"}
: ${LOCAL_DB_NAME:? "LOCAL_DB_NAME is not set in .env"}
: ${LOCAL_DB_USER:? "LOCAL_DB_USER is not set in .env"}
: ${LOCAL_DB_PASS:? "LOCAL_DB_PASS is not set in .env"}

# Backup production database
echo "Backing up production database..."
if ! ssh "$REMOTE_SSH" "docker exec $REMOTE_DB_CONTAINER mysqldump -u root -p'$REMOTE_DB_ROOT_PASS' $REMOTE_DB_NAME > /tmp/prod-backup.sql"; then
  echo "Backup failed!"
  exit 1
fi

# Sync files
echo "Syncing files from $REMOTE_SSH:$REMOTE_WP_PATH to $LOCAL_WP_PATH..."
if ! rsync -avz --exclude 'wp-config.php' "$REMOTE_SSH:$REMOTE_WP_PATH/" "$LOCAL_WP_PATH/"; then
  echo "File sync failed!"
  exit 1
fi

# Sync database
echo "Transferring and importing production database..."
if ! rsync -avz "$REMOTE_SSH:/tmp/prod-backup.sql" /tmp/prod-backup.sql; then
  echo "Rsync database failed!"
  exit 1
fi
if ! docker cp /tmp/prod-backup.sql "$LOCAL_DB_CONTAINER:/tmp/prod-backup.sql"; then
  echo "Copy to local container failed!"
  exit 1
fi
# prettier-ignore
if ! docker exec "$LOCAL_DB_CONTAINER" mysql -u root -p"$LOCAL_DB_ROOT_PASS" "$LOCAL_DB_NAME" < /tmp/prod-backup.sql; then
  echo "Database import failed!"
  exit 1
fi

# Update URLs using WP-CLI
echo "Updating URLs from $PROD_URL to $LOCAL_URL..."
if ! docker exec "$LOCAL_WP_CONTAINER" wp search-replace "$PROD_URL" "$LOCAL_URL" --all-tables --precise --allow-root; then
  echo "URL update failed!"
  exit 1
fi

# Clean up
echo "Cleaning up temporary files..."
rm -v /tmp/prod-backup.sql
docker exec "$LOCAL_DB_CONTAINER" rm -v /tmp/prod-backup.sql
ssh "$REMOTE_SSH" rm -v /tmp/prod-backup.sql

echo "Sync complete!"
