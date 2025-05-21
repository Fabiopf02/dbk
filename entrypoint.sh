#!/bin/sh

# Usa variável de ambiente ou valor padrão
: "${CRON_SCHEDULE:=* */12 * * *}"

# Gera o crontab dinamicamente
echo "$CRON_SCHEDULE /scripts/pg_backup.sh >> /var/log/pg_backup.log 2>&1" >> /etc/crontabs/root

chmod /etc/crontabs/root
crontab /etc/crontabs/root

# Inicia o cron em foreground
crond -l 2 -L /var/log/pg_backup_error.log
tail -f /var/log/pg_backup_error.log

