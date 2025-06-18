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
: ${STAGE_SSH:? "STAGE_SSH is not set in .env"}
: ${STAGE_DB_CONTAINER:? "STAGE_DB_CONTAINER is not set in .env"}
: ${STAGE_WP_PATH:? "STAGE_WP_PATH is not set in .env"}
: ${STAGE_WP_URL:? "STAGE_WP_URL is not set in .env"}
: ${STAGE_DB_NAME:? "STAGE_DB_NAME is not set in .env"}
: ${STAGE_DB_ROOT_PASSWORD:? "STAGE_DB_ROOT_PASSWORD is not set in .env"}
: ${STAGE_DB_USER:? "STAGE_DB_USER is not set in .env"}
: ${STAGE_DB_PASSWORD:? "STAGE_DB_PASSWORD is not set in .env"}
: ${PROD_SSH:? "PROD_SSH is not set in .env"}
: ${PROD_DB_CONTAINER:? "PROD_DB_CONTAINER is not set in .env"}
: ${PROD_WP_PATH:? "PROD_WP_PATH is not set in .env"}
: ${PROD_WP_URL:? "PROD_WP_URL is not set in .env"}
: ${PROD_DB_NAME:? "PROD_DB_NAME is not set in .env"}
: ${PROD_DB_ROOT_PASSWORD:? "PROD_DB_ROOT_PASSWORD is not set in .env"}
: ${PROD_DB_USER:? "PROD_DB_USER is not set in .env"}
: ${PROD_DB_PASSWORD:? "PROD_DB_PASSWORD is not set in .env"}

# Backup staging database
echo "Backing up staging database..."
ssh "$STAGE_SSH" "docker exec -i $STAGE_DB_CONTAINER mysqldump -u root -p\"$STAGE_DB_ROOT_PASSWORD\" \"$STAGE_DB_NAME\" > /tmp/stage-backup.sql" || {
  echo "Backup failed!"
  exit 1
}

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

# Sync database
echo "Transferring and importing staging database to production..."
if [ "$STAGE_SSH" = "$PROD_SSH" ]; then
  # Same server: no need to rsync, file is already at /tmp/stage-backup.sql
  echo "Same server detected, skipping rsync for database backup..."
else
  # Different servers: transfer database backup
  rsync -avz "$STAGE_SSH:/tmp/stage-backup.sql" "$PROD_SSH:/tmp/stage-backup.sql" || {
    echo "Rsync database failed!"
    exit 1
  }
fi
ssh "$PROD_SSH" "docker cp /tmp/stage-backup.sql $PROD_DB_CONTAINER:/tmp/stage-backup.sql" || {
  echo "Copy to production container failed!"
  exit 1
}
ssh "$PROD_SSH" "docker exec -i $PROD_DB_CONTAINER mysql -u root -p\"$PROD_DB_ROOT_PASSWORD\" \"$PROD_DB_NAME\" < /tmp/stage-backup.sql" || {
  echo "Database import failed!"
  exit 1
}

# Update URLs in the production database
echo "Updating URLs from $STAGE_WP_URL to $PROD_WP_URL..."
ssh "$PROD_SSH" "docker exec $PROD_DB_CONTAINER mysql -v -u \"$PROD_DB_USER\" -p\"$PROD_DB_PASSWORD\" \"$PROD_DB_NAME\" -e \"UPDATE wp_options SET option_value = REPLACE(option_value, '$STAGE_WP_URL', '$PROD_WP_URL') WHERE option_name IN ('siteurl', 'home');\"" || {
  echo "URL update failed!"
  exit 1
}
ssh "$PROD_SSH" "docker exec $PROD_DB_CONTAINER mysql -v -u \"$PROD_DB_USER\" -p\"$PROD_DB_PASSWORD\" \"$PROD_DB_NAME\" -e \"UPDATE wp_posts SET guid = REPLACE(guid, '$STAGE_WP_URL', '$PROD_WP_URL');\"" || {
  echo "GUID update failed!"
  exit 1
}
ssh "$PROD_SSH" "docker exec $PROD_DB_CONTAINER mysql -v -u \"$PROD_DB_USER\" -p\"$PROD_DB_PASSWORD\" \"$PROD_DB_NAME\" -e \"UPDATE wp_posts SET post_content = REPLACE(post_content, '$STAGE_WP_URL', '$PROD_WP_URL');\"" || {
  echo "Post content update failed!"
  exit 1
}
ssh "$PROD_SSH" "docker exec $PROD_DB_CONTAINER mysql -v -u \"$PROD_DB_USER\" -p\"$PROD_DB_PASSWORD\" \"$PROD_DB_NAME\" -e \"UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, '$STAGE_WP_URL', '$PROD_WP_URL');\"" || {
  echo "Postmeta update failed!"
  exit 1
}

# Clean up
echo "Cleaning up temporary files..."
ssh "$STAGE_SSH" "rm -v /tmp/stage-backup.sql"
ssh "$PROD_SSH" "docker exec $PROD_DB_CONTAINER rm -v /tmp/stage-backup.sql"
if [ "$STAGE_SSH" != "$PROD_SSH" ]; then
  ssh "$PROD_SSH" "rm -v /tmp/stage-backup.sql"
fi

echo "Sync from stage to production complete!"
