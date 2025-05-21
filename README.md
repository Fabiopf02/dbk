# dbk

Automated backup for databases running in Docker containers, with support for cron scheduling, S3/Google Drive upload, and Discord notifications.

---

## How It Works

This container periodically backs up PostgreSQL databases (or others, if adapted), saving dumps locally and/or sending them to remote destinations. The schedule is fully configurable via environment variable.

## How to Use

### 1. Prerequisites

- Docker installed
- The database must be running in a container and on the same Docker network as the backup container

---

### 2. rclone configuration (Google Drive / S3)

To use Google Drive or S3 as backup destinations, you must provide a valid `rclone.conf` file with the necessary credentials. Learn how to generate your configuration file for Google Drive or/and S3 in the [official rclone documentation](https://rclone.org/docs/). For an example of how your file should look, see the [`rclone/rclone.example.conf`](https://github.com/Fabiopf02/dbk/blob/main/rclone/rclone.example.conf) file in this repository.

- For Google Drive: [rclone Google Drive documentation](https://rclone.org/drive/)
- For S3 (Amazon or compatible): [rclone S3 documentation](https://rclone.org/s3/)

> **After generating your `rclone.conf`:** Place the `rclone.conf` file inside a directory named `rclone` (for example, `./rclone/rclone.conf`). This directory should be in the same location where you run your `docker run` or `docker compose` commands. This way, you can mount the entire `rclone` directory as a volume into the container, as shown in the usage examples below. The configuration file will be used to enable backup to cloud providers.

---

### 3. Using the published image

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

#### Custom pg_dump options

You can use the `PG_DUMP_EXTRA_OPTS` environment variable to pass custom options to `pg_dump`. For example, to dump only a specific schema, set:

```env
PG_DUMP_EXTRA_OPTS=-n "myschema"
```

#### Example directory structure

Before running the container, your project directory should look like this:

```text
project-root/
├── .env
├── pg_dumps/
└── rclone/
    └── rclone.conf
```

#### Run the backup container

> **Important:** Replace `db-network` with your database network name.

```sh
docker run -d \
  --name dbk \
  --env-file .env \
  -v $(pwd)/pg_dumps:/pg_dumps \
  -v $(pwd)/rclone:/root/.config/rclone \
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
| PG_DUMP_EXTRA_OPTS | Extra options to pass to pg_dump (e.g., `-n "myschema"`) | No | `-n "myschema"` |

---

## Tips & Notes

- The backup container must be on the same Docker network as the database.
- Use the database container name as the value for `DB_HOST`.
- Backups are saved in `/pg_dumps` inside the container (mount a local volume for persistence).
- You can change the schedule anytime by updating `CRON_SCHEDULE` and restarting the container.
