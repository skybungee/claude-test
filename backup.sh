#!/bin/bash
################################################################################
# Linux Backup Script
# Description: Automated backup script with rotation and logging
# Usage: ./backup.sh [options]
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_METHOD="tar"  # Options: tar, rsync
BACKUP_SOURCE=""
BACKUP_DEST=""
RETENTION_DAYS=7
LOG_FILE=""
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}"
COMPRESS=true
EXCLUDE_FILE=""
DRY_RUN=false

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    [ -n "$LOG_FILE" ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    [ -n "$LOG_FILE" ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    [ -n "$LOG_FILE" ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -s, --source PATH           Source directory to backup (required)
    -d, --destination PATH      Destination directory for backups (required)
    -m, --method METHOD         Backup method: tar or rsync (default: tar)
    -r, --retention DAYS        Number of days to keep backups (default: 7)
    -l, --log FILE              Log file path (default: no logging)
    -e, --exclude FILE          File containing exclude patterns (one per line)
    -n, --no-compress           Disable compression (tar method only)
    --dry-run                   Show what would be done without doing it
    -h, --help                  Display this help message

Examples:
    # Basic backup with tar
    $0 -s /home/user -d /backup/location

    # Backup with rsync and 14-day retention
    $0 -s /var/www -d /backup/www -m rsync -r 14

    # Backup with exclusions and logging
    $0 -s /home -d /backup -e exclude.txt -l /var/log/backup.log

EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--source)
                BACKUP_SOURCE="$2"
                shift 2
                ;;
            -d|--destination)
                BACKUP_DEST="$2"
                shift 2
                ;;
            -m|--method)
                BACKUP_METHOD="$2"
                shift 2
                ;;
            -r|--retention)
                RETENTION_DAYS="$2"
                shift 2
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -e|--exclude)
                EXCLUDE_FILE="$2"
                shift 2
                ;;
            -n|--no-compress)
                COMPRESS=false
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Validate configuration
validate_config() {
    local error=0

    if [ -z "$BACKUP_SOURCE" ]; then
        log_error "Source directory not specified"
        error=1
    elif [ ! -d "$BACKUP_SOURCE" ]; then
        log_error "Source directory does not exist: $BACKUP_SOURCE"
        error=1
    fi

    if [ -z "$BACKUP_DEST" ]; then
        log_error "Destination directory not specified"
        error=1
    fi

    if [ "$BACKUP_METHOD" != "tar" ] && [ "$BACKUP_METHOD" != "rsync" ]; then
        log_error "Invalid backup method: $BACKUP_METHOD (must be tar or rsync)"
        error=1
    fi

    if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
        log_error "Retention days must be a positive integer"
        error=1
    fi

    if [ -n "$EXCLUDE_FILE" ] && [ ! -f "$EXCLUDE_FILE" ]; then
        log_error "Exclude file does not exist: $EXCLUDE_FILE"
        error=1
    fi

    # Check for required tools
    if [ "$BACKUP_METHOD" == "rsync" ] && ! command -v rsync &> /dev/null; then
        log_error "rsync is not installed"
        error=1
    fi

    if [ $error -eq 1 ]; then
        exit 1
    fi
}

# Create destination directory if it doesn't exist
prepare_destination() {
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would create destination directory: $BACKUP_DEST"
        return
    fi

    if [ ! -d "$BACKUP_DEST" ]; then
        log_info "Creating destination directory: $BACKUP_DEST"
        mkdir -p "$BACKUP_DEST"
    fi
}

# Perform tar backup
backup_tar() {
    local archive_name="${BACKUP_NAME}.tar"
    local tar_opts="cf"

    if [ "$COMPRESS" = true ]; then
        archive_name="${BACKUP_NAME}.tar.gz"
        tar_opts="czf"
        log_info "Using gzip compression"
    fi

    local backup_path="${BACKUP_DEST}/${archive_name}"

    log_info "Starting tar backup..."
    log_info "Source: $BACKUP_SOURCE"
    log_info "Destination: $backup_path"

    local exclude_opts=""
    if [ -n "$EXCLUDE_FILE" ]; then
        exclude_opts="--exclude-from=$EXCLUDE_FILE"
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would execute: tar $tar_opts $backup_path -C $BACKUP_SOURCE . $exclude_opts"
        return 0
    fi

    # Create tar archive
    if tar $tar_opts "$backup_path" -C "$BACKUP_SOURCE" . $exclude_opts 2>&1 | tee -a "$LOG_FILE"; then
        local size=$(du -h "$backup_path" | cut -f1)
        log_info "Backup completed successfully"
        log_info "Backup size: $size"
        return 0
    else
        log_error "Backup failed"
        return 1
    fi
}

# Perform rsync backup
backup_rsync() {
    local backup_path="${BACKUP_DEST}/${BACKUP_NAME}"

    log_info "Starting rsync backup..."
    log_info "Source: $BACKUP_SOURCE"
    log_info "Destination: $backup_path"

    local rsync_opts="-avh --delete"

    if [ "$DRY_RUN" = true ]; then
        rsync_opts="$rsync_opts --dry-run"
    fi

    if [ -n "$EXCLUDE_FILE" ]; then
        rsync_opts="$rsync_opts --exclude-from=$EXCLUDE_FILE"
    fi

    # Create backup directory
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$backup_path"
    fi

    # Perform rsync
    if rsync $rsync_opts "$BACKUP_SOURCE/" "$backup_path/" 2>&1 | tee -a "$LOG_FILE"; then
        if [ "$DRY_RUN" = false ]; then
            local size=$(du -sh "$backup_path" | cut -f1)
            log_info "Backup completed successfully"
            log_info "Backup size: $size"
        else
            log_info "DRY RUN completed"
        fi
        return 0
    else
        log_error "Backup failed"
        return 1
    fi
}

# Clean old backups based on retention policy
cleanup_old_backups() {
    log_info "Cleaning up backups older than $RETENTION_DAYS days..."

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would delete backups older than $RETENTION_DAYS days:"
        find "$BACKUP_DEST" -maxdepth 1 -type f -name "backup_*" -mtime +$RETENTION_DAYS -o \
             -maxdepth 1 -type d -name "backup_*" -mtime +$RETENTION_DAYS 2>/dev/null | while read -r old_backup; do
            log_info "  - $old_backup"
        done
        return
    fi

    local count=0
    # Find and delete old backup files and directories
    find "$BACKUP_DEST" -maxdepth 1 \( -type f -o -type d \) -name "backup_*" -mtime +$RETENTION_DAYS 2>/dev/null | while read -r old_backup; do
        log_info "Removing old backup: $old_backup"
        rm -rf "$old_backup"
        count=$((count + 1))
    done

    if [ $count -eq 0 ]; then
        log_info "No old backups to remove"
    else
        log_info "Removed $count old backup(s)"
    fi
}

# Main function
main() {
    log_info "=========================================="
    log_info "Linux Backup Script Started"
    log_info "=========================================="

    parse_args "$@"
    validate_config
    prepare_destination

    # Perform backup based on method
    case $BACKUP_METHOD in
        tar)
            backup_tar
            ;;
        rsync)
            backup_rsync
            ;;
    esac

    local backup_status=$?

    if [ $backup_status -eq 0 ]; then
        cleanup_old_backups
        log_info "=========================================="
        log_info "Backup Process Completed Successfully"
        log_info "=========================================="
        exit 0
    else
        log_error "=========================================="
        log_error "Backup Process Failed"
        log_error "=========================================="
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
