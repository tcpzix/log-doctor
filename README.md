# Log Doctor

A simple bash script to analyze and clean up server logs on Linux. Helps reclaim disk space when `/var/log` grows too large.

## Requirements

- Linux (Debian or Red Hat based)
- Root access
- systemd (for journal options)

## Usage

```bash
sudo ./log-doc.sh
```

## What it does

1. **Scans** `/var/log` and reports:
   - Total log directory size
   - Journal size
   - Count of large files (>50M)
   - Top 10 biggest log files
   - Top processes writing to syslog

2. **Offers cleanup options:**
   - Vacuum journal to 200MB
   - Truncate active logs
   - Remove rotated logs (.gz, .1, .2, etc.)
   - Apply journald disk limits (200MB max, 7-day retention)
   - Run all of the above

## ⚠️ Warning

This script modifies and deletes log files. Run only if you understand the impact. Consider backing up important logs first.
