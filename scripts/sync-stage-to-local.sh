#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the database and files sync scripts
"$SCRIPT_DIR/sync-db-stage-to-local.sh"
"$SCRIPT_DIR/sync-files-stage-to-local.sh"