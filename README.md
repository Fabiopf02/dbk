# dbk

Automated backup for databases running in Docker containers, with support for cron scheduling, S3/Google Drive upload, and Discord notifications.

---

## How It Works

This container periodically backs up PostgreSQL databases (or others, if adapted), saving dumps locally and/or sending them to remote destinations. The schedule is fully configurable via environment variable.

---

## How to Use

### 1. Prerequisites

- Docker installed
- The database must be running in a container and on the same Docker network as the backup container

---

### 2. Using the published image

Pull the image from Docker Hub:

```sh
docker pull f4b1002/dbk:latest
```

#### Create your `.env` file (example):

```env
DB_HOST=my_postgres
DB_USER=user
DB_PASSWORD=secret
DB_NAME=mydb
DB_PORT=5432

# Number of days to keep the dumps (optional, default: 5)
DUMP_RETENTION_DAYS=

S3_PATH=bucket_name/dumps # start with bucket name
GDRIVE_PATH=dumps

CRON_SCHEDULE=0 3 * * *
WEBHOOK_URL=https://discord.com/api/webhooks/...
```

#### Run the backup container

> **Important:** Replace `db-network` with your database network name.

```sh
docker run -d \
  --name dbk \
  --env-file .env \
  -v $(pwd)/pg_dumps:/pg_dumps \
  -v $(pwd)/rclone.conf:/root/.config/rclone \
  --network db-network \
  f4b1002/dbk:latest
```

---

### 3. Building the image locally

Clone the repository:

```sh
git clone https://github.com/Fabiopf02/dbk.git
cd dbk
```

Build the image:

```sh
docker compose build
```
---

## Environment Variables

| Variable        | Description                                  | Required    | Example                                |
|-----------------|----------------------------------------------|-------------|----------------------------------------|
| DB_HOST         | Database host                                | Yes         | `my_postgres`                          |
| DB_USER         | Database user                                | Yes         | `postgres`                             |
| DB_PASSWORD     | Database password                            | Yes         | `mypassword`                           |
| DB_NAME         | Database name                                | Yes         | `mydb`                                 |
| DB_PORT         | Database port                                | No          | `5432`                                 |
| CRON_SCHEDULE   | Backup schedule (cron)                       | Yes         | `0 3 * * *`                            |
| S3_PATH         | S3 path                                      | No          | `bucket_name/dumps`                    |
| GDRIVE_PATH     | Google Drive path                            | No          | `dumps`                                |
| WEBHOOK_URL     | Discord webhook URL (notifications, optional) | No          | `https://discord.com/api/webhooks/...` |
| DUMP_RETENTION_DAYS | Number of days to keep dumps (optional, default: 5) | No | `7` (default: 5) |

---

## Tips & Notes

- The backup container must be on the same Docker network as the database.
- Use the database container name as the value for `DB_HOST`.
- Backups are saved in `/pg_dumps` inside the container (mount a local volume for persistence).
- You can change the schedule anytime by updating `CRON_SCHEDULE` and restarting the container.
