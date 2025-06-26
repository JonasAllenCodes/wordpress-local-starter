#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the database and files sync scripts
"$SCRIPT_DIR/sync-db-local-to-stage.sh"
"$SCRIPT_DIR/sync-files-local-to-stage.sh"