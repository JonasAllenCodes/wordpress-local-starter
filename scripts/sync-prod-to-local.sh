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
read -p "WARNING: This will overwrite local data with production data. Are you sure you want to sync from production to local? (y/N) " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
  echo "Sync cancelled."
  exit 1
fi

# Set default values for variables (if not set in .env)
LOCAL_WP_PORT="${LOCAL_WP_PORT:-8080}"
LOCAL_WP_URL="${LOCAL_WP_URL:-http://localhost:$LOCAL_WP_PORT}"
LOCAL_DB_USER="${LOCAL_DB_USER:-wordpress}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-wordpress}"
LOCAL_DB_NAME="${LOCAL_DB_NAME:-wordpress}"
LOCAL_DB_ROOT_PASSWORD="${LOCAL_DB_ROOT_PASSWORD:-wordpress}"

# Verify required variables
: ${PROD_SSH:? "PROD_SSH is not set in .env"}
: ${PROD_DB_CONTAINER:? "PROD_DB_CONTAINER is not set in .env"}
: ${PROD_WP_PATH:? "PROD_WP_PATH is not set in .env"}
: ${LOCAL_DB_CONTAINER:? "LOCAL_DB_CONTAINER is not set in .env"}
: ${PROD_WP_URL:? "PROD_WP_URL is not set in .env"}
: ${PROD_DB_NAME:? "PROD_DB_NAME is not set in .env"}
: ${PROD_DB_ROOT_PASSWORD:? "PROD_DB_ROOT_PASSWORD is not set in .env"}
: ${PROD_DB_USER:? "PROD_DB_USER is not set in .env"}
: ${PROD_DB_PASSWORD:? "PROD_DB_PASSWORD is not set in .env"}

# Backup production database
echo "Backing up production database..."
ssh "$PROD_SSH" " docker exec -i $PROD_DB_CONTAINER  mysqldump -u root -p$PROD_DB_ROOT_PASSWORD $PROD_DB_NAME > /tmp/prod-backup.sql" || {
  echo "Backup failed!"
  exit 1
}

# Sync files
echo "Syncing files from $PROD_SSH:$PROD_WP_PATH to ./wp-content..."
rsync -avz --progress --delete --exclude 'wp-config.php' "$PROD_SSH:$PROD_WP_PATH/" "./wp-content" || {
  echo "File sync failed!"
  exit 1
}

# Sync database
echo "Transferring and importing production database..."
rsync -avz "$PROD_SSH:/tmp/prod-backup.sql" /tmp/prod-backup.sql || {
  echo "Rsync database failed!"
  exit 1
}
docker cp /tmp/prod-backup.sql "$LOCAL_DB_CONTAINER:/tmp/prod-backup.sql" || {
  echo "Copy to local container failed!"
  exit 1
}
docker exec -i "$LOCAL_DB_CONTAINER" mysql -u root -p"$LOCAL_DB_ROOT_PASSWORD" "$LOCAL_DB_NAME" </tmp/prod-backup.sql || {
  echo "Database import failed!"
  exit 1
}

# Update URLs in the database
echo "Updating URLs from $PROD_WP_URL to $LOCAL_WP_URL..."
docker exec "$LOCAL_DB_CONTAINER" mysql -v -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PASSWORD" "$LOCAL_DB_NAME" -e "UPDATE wp_options SET option_value = REPLACE(option_value, '$PROD_WP_URL', '$LOCAL_WP_URL') WHERE option_name IN ('siteurl', 'home');" || {
  echo "URL update failed!"
  exit 1
}
docker exec "$LOCAL_DB_CONTAINER" mysql -v -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PASSWORD" "$LOCAL_DB_NAME" -e "UPDATE wp_posts SET guid = REPLACE(guid, '$PROD_WP_URL', '$LOCAL_WP_URL');" || {
  echo "GUID update failed!"
  exit 1
}
docker exec "$LOCAL_DB_CONTAINER" mysql -v -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PASSWORD" "$LOCAL_DB_NAME" -e "UPDATE wp_posts SET post_content = REPLACE(post_content, '$PROD_WP_URL', '$LOCAL_WP_URL');" || {
  echo "Post content update failed!"
  exit 1
}
docker exec "$LOCAL_DB_CONTAINER" mysql -v -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PASSWORD" "$LOCAL_DB_NAME" -e "UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$PROD_WP_URL', '$LOCAL_WP_URL');" || {
  echo "Postmeta update failed!"
  exit 1
}

# Clean up
echo "Cleaning up temporary files..."
rm -v /tmp/prod-backup.sql
docker exec "$LOCAL_DB_CONTAINER" rm -v /tmp/prod-backup.sql
ssh "$PROD_SSH" "rm -v /tmp/prod-backup.sql"

echo "Sync from production to local complete!"
