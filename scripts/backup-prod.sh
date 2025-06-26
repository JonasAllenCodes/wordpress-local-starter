#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the database and files backup scripts
"$SCRIPT_DIR/backup-prod-db.sh"
"$SCRIPT_DIR/backup-prod-files.sh"
