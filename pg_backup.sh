#!/bin/sh

set -e

[ -f /scripts/.env ] && export $(grep -v '^#' /scripts/.env | xargs)

TS=$(date +"%F_%H-%M-%S")
DUMP_FILE="/pg_dumps/dump_$DB_NAME-$TS"

log() {
  echo "[$(date '+%F %T')] $1"
}

notify_discord() {
  local STATUS=$1
  local MESSAGE=$2

  if [ -n "$WEBHOOK_URL" ]; then
    curl -s -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"content\":\":floppy_disk:  **Backup PostgreSQL**   |   $STATUS\n$MESSAGE\"}"
  fi
}

handle_error() {
  local MSG="Erro ao executar backup em $TS"
  local ERR_MSG="Não foi possível concluir o backup. Consultar logs..."
  
  log "$MSG"
  log "$ERR_MSG"

  notify_discord "❌ Erro" "$(printf "📅 **Data:** %s\n🕒 **Hora:** %s\n🗄️ **Banco:** \`%s\`\n💬 **Erro:** \`\`\`\n%s\n\`\`\`" "$(date '+%F')" "$(date '+%T')" "$DB_NAME" "$ERR_MSG")"

  exit 1
}

trap handle_error ERR

log "Iniciando pg_dump para $DB_NAME..."

PGPASSWORD=$DB_PASSWORD pg_dump \
  --verbose \
  --host=$DB_HOST \
  --port=$DB_PORT \
  --username=$DB_USER \
  --format=c \
  --compress=8 \
  --encoding=UTF-8 \
  --no-owner \
  --create \
  --file "$DUMP_FILE" \
  ${PG_DUMP_EXTRA_OPTS} \
  "$DB_NAME" 2>&1 | tee -a /var/log/pg_backup_error.log

log "Dump concluído: $DUMP_FILE"

if [ -n "$S3_PATH" ]; then
  rclone copy "$DUMP_FILE" s3:"$S3_PATH"/ 2>&1 | tee -a /var/log/pg_backup_error.log
fi

if [ -n "$GDRIVE_PATH" ]; then
  rclone copy "$DUMP_FILE" gdrive:"$GDRIVE_PATH"/ 2>&1 | tee -a /var/log/pg_backup_error.log
fi

# Clean old dumps: Configurable value (default 5 days)
RETENTION_DAYS="${DUMP_RETENTION_DAYS:-5}"
find /pg_dumps -type f -mtime +$RETENTION_DAYS -name "pg_dump_*" -exec rm {} \;

log "Limpeza de dumps antigos concluída."

notify_discord "✅ Sucesso" "📅 **Data:** $(date '+%F')\n🕒 **Hora:** $(date '+%T')\n🗄️ **Banco:** \`$DB_NAME\`\n📁 **Arquivo:** \`$(basename "$DUMP_FILE")\`\n☁️ **Destino:** S3: $S3_BUCKET/$S3_PATH"
