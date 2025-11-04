#!/bin/bash
################################################################################
# Example Backup Configuration Script
# Customize this script for your specific backup needs
################################################################################

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to the main backup script
BACKUP_SCRIPT="${SCRIPT_DIR}/backup.sh"

# Configuration
SOURCE_DIR="/home/user"          # Change to your source directory
BACKUP_DIR="/backup/location"    # Change to your backup destination
RETENTION_DAYS=7                 # Number of days to keep backups
LOG_FILE="/var/log/backup.log"   # Log file path
EXCLUDE_FILE="${SCRIPT_DIR}/exclude.txt"  # Exclusion patterns

# Run the backup
"${BACKUP_SCRIPT}" \
    --source "${SOURCE_DIR}" \
    --destination "${BACKUP_DIR}" \
    --method tar \
    --retention ${RETENTION_DAYS} \
    --log "${LOG_FILE}" \
    --exclude "${EXCLUDE_FILE}"
