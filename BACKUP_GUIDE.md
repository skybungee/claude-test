# Linux Backup Script Guide

A comprehensive, production-ready backup script for Linux systems with support for multiple backup methods, rotation policies, and detailed logging.

## Features

- **Multiple Backup Methods**: Support for both `tar` and `rsync` backups
- **Compression**: Optional gzip compression for tar backups
- **Retention Policy**: Automatic cleanup of old backups based on configurable retention period
- **Exclusion Patterns**: Support for excluding files/directories from backups
- **Logging**: Detailed logging with timestamps and color-coded output
- **Dry Run Mode**: Preview what the script will do without making changes
- **Error Handling**: Robust error checking and reporting

## Prerequisites

- Linux/Unix system
- Bash shell
- `tar` (usually pre-installed)
- `rsync` (required only for rsync backup method)

Install rsync if needed:
```bash
# Debian/Ubuntu
sudo apt-get install rsync

# RHEL/CentOS/Fedora
sudo yum install rsync

# Arch Linux
sudo pacman -S rsync
```

## Installation

1. Clone or download the backup script
2. Make it executable:
```bash
chmod +x backup.sh
```

## Basic Usage

### Simple Backup with tar (default)
```bash
./backup.sh -s /home/user -d /backup/location
```

### Backup with rsync
```bash
./backup.sh -s /home/user -d /backup/location -m rsync
```

### Backup with Custom Retention (14 days)
```bash
./backup.sh -s /var/www -d /backup/www -r 14
```

### Backup with Exclusions and Logging
```bash
./backup.sh -s /home -d /backup -e exclude.txt -l /var/log/backup.log
```

### Test with Dry Run
```bash
./backup.sh -s /home/user -d /backup --dry-run
```

## Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-s, --source PATH` | Source directory to backup (required) | - |
| `-d, --destination PATH` | Destination directory for backups (required) | - |
| `-m, --method METHOD` | Backup method: `tar` or `rsync` | `tar` |
| `-r, --retention DAYS` | Number of days to keep backups | `7` |
| `-l, --log FILE` | Log file path | No logging |
| `-e, --exclude FILE` | File containing exclude patterns | None |
| `-n, --no-compress` | Disable compression (tar only) | Compression enabled |
| `--dry-run` | Show what would be done without executing | Disabled |
| `-h, --help` | Display help message | - |

## Backup Methods

### TAR Method
- Creates compressed archive files (`.tar.gz`)
- Good for full system backups
- Takes less space with compression
- Each backup is a complete snapshot
- File naming: `backup_YYYYMMDD_HHMMSS.tar.gz`

### RSYNC Method
- Creates directory copies with hard links
- More efficient for incremental backups
- Preserves file permissions and attributes
- Uses `--delete` flag to mirror source
- Directory naming: `backup_YYYYMMDD_HHMMSS/`

## Exclusion Patterns

Create an `exclude.txt` file with patterns to exclude from backups (one pattern per line):

```
# Temporary files
*.tmp
*.temp

# Cache directories
.cache/
__pycache__/

# Large directories
node_modules/
Videos/

# System files
.git/
.DS_Store
```

## Automation with Cron

To run backups automatically, add to crontab:

```bash
# Edit crontab
crontab -e

# Add entries:

# Daily backup at 2 AM
0 2 * * * /path/to/backup.sh -s /home/user -d /backup/daily -l /var/log/backup.log

# Weekly backup on Sunday at 3 AM
0 3 * * 0 /path/to/backup.sh -s /home/user -d /backup/weekly -r 30 -l /var/log/backup.log

# Monthly backup on 1st day at 4 AM
0 4 1 * * /path/to/backup.sh -s /home/user -d /backup/monthly -r 90 -l /var/log/backup.log
```

## Examples

### 1. Home Directory Backup (Daily)
```bash
#!/bin/bash
./backup.sh \
    -s /home/user \
    -d /backup/home \
    -e exclude.txt \
    -r 7 \
    -l /var/log/home-backup.log
```

### 2. Website Backup with rsync
```bash
#!/bin/bash
./backup.sh \
    -s /var/www/html \
    -d /backup/websites \
    -m rsync \
    -r 14 \
    -l /var/log/web-backup.log
```

### 3. Database Backup Directory
```bash
#!/bin/bash
./backup.sh \
    -s /var/backups/database \
    -d /backup/db \
    -r 30 \
    -l /var/log/db-backup.log
```

### 4. System Configuration Backup
```bash
#!/bin/bash
./backup.sh \
    -s /etc \
    -d /backup/config \
    -m tar \
    -r 90 \
    -l /var/log/config-backup.log
```

## Retention Policy

The script automatically removes backups older than the specified retention period:
- Retention is checked after each successful backup
- Only backups matching the pattern `backup_*` are affected
- Both tar archives and rsync directories are cleaned up

## Logging

When a log file is specified with `-l`:
- All operations are logged with timestamps
- Color-coded console output (INFO in green, ERROR in red, WARN in yellow)
- Both stdout and log file receive messages
- Useful for troubleshooting and audit trails

## Security Considerations

1. **Permissions**: Ensure the backup script runs with appropriate permissions
2. **Backup Location**: Store backups on a different physical disk/location
3. **Encryption**: Consider encrypting sensitive backups
4. **Access Control**: Restrict access to backup files (e.g., `chmod 600`)
5. **Testing**: Regularly test backup restoration

## Troubleshooting

### Permission Denied
```bash
# Run with sudo if backing up system files
sudo ./backup.sh -s /etc -d /backup/config
```

### Insufficient Space
```bash
# Check available space
df -h /backup

# Reduce retention period or clean old backups
./backup.sh -s /home -d /backup -r 3
```

### rsync Not Found
```bash
# Install rsync
sudo apt-get install rsync  # Debian/Ubuntu
sudo yum install rsync      # RHEL/CentOS
```

## Restoration

### From TAR Backup
```bash
# Extract to current directory
tar -xzf /backup/location/backup_20231104_120000.tar.gz -C /restore/path

# List contents without extracting
tar -tzf /backup/location/backup_20231104_120000.tar.gz
```

### From RSYNC Backup
```bash
# Copy back from rsync backup
rsync -avh /backup/location/backup_20231104_120000/ /restore/path/

# Or simply copy the directory
cp -a /backup/location/backup_20231104_120000/ /restore/path/
```

## Best Practices

1. **Test First**: Always run with `--dry-run` before setting up automated backups
2. **Multiple Locations**: Keep backups in multiple locations (local + remote)
3. **Regular Testing**: Periodically test restoration procedures
4. **Monitor Logs**: Review backup logs regularly for errors
5. **Document**: Keep notes on what's backed up and where
6. **Version Control**: Keep the backup script in version control
7. **Incremental Strategy**: Use different retention for daily/weekly/monthly backups

## License

This script is provided as-is for use in your Linux backup strategy.
