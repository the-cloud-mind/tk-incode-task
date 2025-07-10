#!/bin/bash

# ——— logging ———
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting User Data as $(whoami)"

# ——— vars (customize these) ———
S3_BUCKET="tk-demo-app"
S3_PREFIX="demo-app"
LOCAL_DATA_DIR="/opt/app/data"

# ——— initial sync & deploy ———
mkdir -p "$LOCAL_DATA_DIR"
echo "Syncing S3 → $LOCAL_DATA_DIR"
aws s3 sync "s3://$S3_BUCKET/$S3_PREFIX" "$LOCAL_DATA_DIR" --delete

echo "Running docker compose"
cd "$LOCAL_DATA_DIR"
docker compose up -d

# ——— helper script for cron ———
cat << EOF > /usr/local/bin/sync-and-deploy.sh
#!/bin/bash
exec > >(tee /var/log/sync-and-deploy.log | logger -t sync-and-deploy -s 2>/dev/console) 2>&1

# dry-run to see if anything changed
DRYRUN=$(aws s3 sync "s3://$S3_BUCKET/$S3_PREFIX" "$LOCAL_DATA_DIR" --delete --dryrun)

if [ -z "$DRYRUN" ]; then
  echo "$(date): No changes detected in S3; skipping sync."
  exit 0
fi

echo "$(date): Changes detected, performing real sync."
aws s3 sync "s3://$S3_BUCKET/$S3_PREFIX" "$LOCAL_DATA_DIR" --delete
cd "$COMPOSE_DIR"
docker compose up -d
EOF
chmod +x /usr/local/bin/sync-and-deploy.sh

# ——— cron job (every day at 3 AM) ———
cat << EOF > /etc/cron.d/sync-and-deploy
# minute hour day month weekday user    command
0 3 * * * root /usr/local/bin/sync-and-deploy.sh
EOF
chmod 644 /etc/cron.d/sync-and-deploy

echo "User Data complete."