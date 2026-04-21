#!/usr/bin/env bash
# Reset the demo back to its starting position.
# Destructive: hard-resets git to origin/main, drops the orders.user_id
# index, and restarts Postgres to clear the buffer cache.
#
# Run from repo root: ./reset-demo.sh

set -euo pipefail

cd "$(dirname "$0")"

echo "==> Stopping load-gen (curls hitting /orders)..."
pkill -f 'localhost:4000/orders' 2>/dev/null || true

echo "==> Stopping Next.js dev server..."
pkill -f 'next dev' 2>/dev/null || true

echo "==> Stopping API (tsx watch)..."
pkill -f 'tsx.*src/index.ts' 2>/dev/null || true

sleep 2

echo "==> Fetching origin..."
git fetch origin main

echo "==> git reset --hard origin/main"
git reset --hard origin/main

echo "==> Dropping idx_orders_user_id..."
docker exec ai-order-demo-db psql -U orders -d orders \
  -c "DROP INDEX IF EXISTS idx_orders_user_id;"

echo "==> Refreshing query planner stats..."
docker exec ai-order-demo-db psql -U orders -d orders -c "ANALYZE orders;"

echo "==> Restarting Postgres (clears buffer cache so the first slow query is actually slow)..."
docker compose restart postgres > /dev/null
until docker exec ai-order-demo-db pg_isready -U orders -d orders > /dev/null 2>&1; do
  sleep 1
done

echo
echo "==> Reset complete. To come back up:"
echo "    (in api/)   npm run dev"
echo "    (in web/)   npm run dev"
echo "    (hidden terminal)   start load-gen loop from DEMO_RUNBOOK.md"
