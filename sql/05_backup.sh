#!/bin/bash
# ArborVida Foundation — Backup Script
# Usage: bash sql/05_backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup/arborvida_backup_$DATE.dump"

pg_dump -U postgres -d arborvida -F c -f "$BACKUP_FILE"

echo "Backup completed: $BACKUP_FILE"
ls -lh "$BACKUP_FILE"
