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

# Set default values for local variables (if not set in .env)
LOCAL_WP_PORT="${LOCAL_WP_PORT:-8080}"
LOCAL_WP_URL="${LOCAL_WP_URL:-http://localhost:$LOCAL_WP_PORT}"
LOCAL_DB_USER="${LOCAL_DB_USER:-wordpress}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-wordpress}"
LOCAL_DB_NAME="${LOCAL_DB_NAME:-wordpress}"
LOCAL_DB_ROOT_PASSWORD="${LOCAL_DB_ROOT_PASSWORD:-wordpress}"

# Verify required variables
: ${LOCAL_DB_CONTAINER:? "LOCAL_DB_CONTAINER is not set in .env"}
: ${STAGE_SSH:? "STAGE_SSH is not set in .env"}
: ${STAGE_DB_CONTAINER:? "STAGE_DB_CONTAINER is not set in .env"}
: ${STAGE_WP_PATH:? "STAGE_WP_PATH is not set in .env"}
: ${STAGE_WP_URL:? "STAGE_WP_URL is not set in .env"}
: ${STAGE_DB_NAME:? "STAGE_DB_NAME is not set in .env"}
: ${STAGE_DB_ROOT_PASSWORD:? "STAGE_DB_ROOT_PASSWORD is not set in .env"}
: ${STAGE_DB_USER:? "STAGE_DB_USER is not set in .env"}
: ${STAGE_DB_PASSWORD:? "STAGE_DB_PASSWORD is not set in .env"}

# Backup local database
echo "Backing up local database..."
docker exec -i "$LOCAL_DB_CONTAINER" mysqldump -u root -p"$LOCAL_DB_ROOT_PASSWORD" "$LOCAL_DB_NAME" >/tmp/local-backup.sql || {
  echo "Local database backup failed!"
  exit 1
}

# Sync files
echo "Syncing files from ./wp-content to $STAGE_SSH:$STAGE_WP_PATH..."
rsync -avz --progress --delete --exclude 'wp-config.php' "./wp-content/" "$STAGE_SSH:$STAGE_WP_PATH/" || {
  echo "File sync failed!"
  exit 1
}

# Sync database
echo "Transferring and importing local database to staging..."
rsync -avz /tmp/local-backup.sql "$STAGE_SSH:/tmp/local-backup.sql" || {
  echo "Rsync database failed!"
  exit 1
}
ssh "$STAGE_SSH" "docker cp /tmp/local-backup.sql $STAGE_DB_CONTAINER:/tmp/local-backup.sql" || {
  echo "Copy to staging container failed!"
  exit 1
}
ssh "$STAGE_SSH" "docker exec -i $STAGE_DB_CONTAINER mysql -u root -p\"$STAGE_DB_ROOT_PASSWORD\" \"$STAGE_DB_NAME\" </tmp/local-backup.sql" || {
  echo "Database import failed!"
  exit 1
}

# Update URLs in the staging database
echo "Updating URLs from $LOCAL_WP_URL to $STAGE_WP_URL..."
ssh "$STAGE_SSH" "docker exec $STAGE_DB_CONTAINER mysql -v -u \"$STAGE_DB_USER\" -p\"$STAGE_DB_PASSWORD\" \"$STAGE_DB_NAME\" -e \"UPDATE wp_options SET option_value = REPLACE(option_value, '$LOCAL_WP_URL', '$STAGE_WP_URL') WHERE option_name IN ('siteurl', 'home');\"" || {
  echo "URL update failed!"
  exit 1
}
ssh "$STAGE_SSH" "docker exec $STAGE_DB_CONTAINER mysql -v -u \"$STAGE_DB_USER\" -p\"$STAGE_DB_PASSWORD\" \"$STAGE_DB_NAME\" -e \"UPDATE wp_posts SET guid = REPLACE(guid, '$LOCAL_WP_URL', '$STAGE_WP_URL');\"" || {
  echo "GUID update failed!"
  exit 1
}
ssh "$STAGE_SSH" "docker exec $STAGE_DB_CONTAINER mysql -v -u \"$STAGE_DB_USER\" -p\"$STAGE_DB_PASSWORD\" \"$STAGE_DB_NAME\" -e \"UPDATE wp_posts SET post_content = REPLACE(post_content, '$LOCAL_WP_URL', '$STAGE_WP_URL');\"" || {
  echo "Post content update failed!"
  exit 1
}
ssh "$STAGE_SSH" "docker exec $STAGE_DB_CONTAINER mysql -v -u \"$STAGE_DB_USER\" -p\"$STAGE_DB_PASSWORD\" \"$STAGE_DB_NAME\" -e \"UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$LOCAL_WP_URL', '$STAGE_WP_URL');\"" || {
  echo "Postmeta update failed!"
  exit 1
}

# Clean up
echo "Cleaning up temporary files..."
rm -v /tmp/local-backup.sql
ssh "$STAGE_SSH" "docker exec $STAGE_DB_CONTAINER rm -v /tmp/local-backup.sql"
ssh "$STAGE_SSH" "rm -v /tmp/local-backup.sql"

echo "Push to staging complete!"
