#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the database and files sync scripts
"$SCRIPT_DIR/sync-db-prod-to-stage.sh"
"$SCRIPT_DIR/sync-files-prod-to-stage.sh"