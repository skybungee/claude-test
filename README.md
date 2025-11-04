# Linux Backup Script

A comprehensive, production-ready backup script for Linux systems with support for multiple backup methods, automatic rotation, and detailed logging.

## Quick Start

```bash
# Make the script executable
chmod +x backup.sh

# Run a basic backup
./backup.sh -s /path/to/source -d /path/to/destination

# View all options
./backup.sh --help
```

## Features

- ✅ Multiple backup methods (tar with compression, rsync)
- ✅ Automatic backup rotation based on retention policy
- ✅ File exclusion patterns support
- ✅ Detailed logging with timestamps
- ✅ Dry-run mode for testing
- ✅ Color-coded output for easy monitoring
- ✅ Robust error handling

## Files

- `backup.sh` - Main backup script
- `BACKUP_GUIDE.md` - Comprehensive usage guide and documentation
- `exclude.txt.example` - Example exclusion patterns file
- `example-backup.sh` - Sample configuration wrapper script

## Documentation

See [BACKUP_GUIDE.md](BACKUP_GUIDE.md) for detailed documentation including:
- Installation instructions
- Usage examples
- Automation with cron
- Restoration procedures
- Best practices

## Example Usage

```bash
# Daily home directory backup with 7-day retention
./backup.sh -s /home/user -d /backup/home -r 7 -l /var/log/backup.log

# Website backup using rsync with exclusions
./backup.sh -s /var/www -d /backup/web -m rsync -e exclude.txt

# Test before running (dry-run mode)
./backup.sh -s /home/user -d /backup --dry-run
```

## License

This script is provided as-is for use in your Linux backup strategy.