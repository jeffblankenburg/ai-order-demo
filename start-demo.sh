#!/usr/bin/env bash
# Bring the demo stack up to a ready-to-perform state.
# Idempotent: safe to run even if some pieces are already running.
#
# Run from repo root: ./start-demo.sh

set -euo pipefail

cd "$(dirname "$0")"

LOG_DIR=.demo-logs
mkdir -p "$LOG_DIR"

is_listening() {
  lsof -iTCP:"$1" -sTCP:LISTEN -n -P > /dev/null 2>&1
}

# 1. Postgres
if ! docker ps --format '{{.Names}}' | grep -q '^ai-order-demo-db$'; then
  echo "==> Starting Postgres..."
  docker compose up -d > /dev/null
fi
echo "==> Waiting for Postgres..."
until docker exec ai-order-demo-db pg_isready -U orders -d orders > /dev/null 2>&1; do
  sleep 1
done

# 2. API on :4000
if is_listening 4000; then
  echo "==> API already up on :4000"
else
  echo "==> Starting API (logs: $LOG_DIR/api.log)..."
  (cd api && nohup npm run dev > "../$LOG_DIR/api.log" 2>&1 & disown) >/dev/null 2>&1
  echo "==> Waiting for API /health..."
  for _ in $(seq 1 30); do
    if curl -sf http://localhost:4000/health > /dev/null 2>&1; then break; fi
    sleep 1
  done
  if ! curl -sf http://localhost:4000/health > /dev/null 2>&1; then
    echo "!! API failed to come up. Check $LOG_DIR/api.log"
    exit 1
  fi
fi

# 3. Web — Next.js picks 3000 if free, 3001 if not
WEB_PORT=""
for p in 3000 3001; do
  if is_listening "$p" && curl -sf "http://localhost:$p" | grep -qi "orders" 2>/dev/null; then
    WEB_PORT="$p"; break
  fi
done

if [[ -n "$WEB_PORT" ]]; then
  echo "==> Web already up on :$WEB_PORT"
else
  echo "==> Starting web (logs: $LOG_DIR/web.log)..."
  (cd web && API_URL=http://localhost:4000 nohup npm run dev > "../$LOG_DIR/web.log" 2>&1 & disown) >/dev/null 2>&1
  echo "==> Waiting for web..."
  for _ in $(seq 1 45); do
    for p in 3000 3001; do
      if curl -sf "http://localhost:$p" | grep -qi "orders" 2>/dev/null; then
        WEB_PORT="$p"; break 2
      fi
    done
    sleep 1
  done
  if [[ -z "$WEB_PORT" ]]; then
    echo "!! Web failed to come up. Check $LOG_DIR/web.log"
    exit 1
  fi
fi

# 4. Load-gen
if pgrep -f 'localhost:4000/orders' > /dev/null 2>&1; then
  echo "==> Load-gen already running"
else
  echo "==> Starting load-gen (logs: $LOG_DIR/loadgen.log)..."
  nohup bash -c 'while true; do curl -s -o /dev/null "http://localhost:4000/orders?userId=$((RANDOM % 1000 + 1))"; sleep 0.5; done' > "$LOG_DIR/loadgen.log" 2>&1 &
  disown
fi

echo
echo "==> Demo is ready."
echo "    Web:   http://localhost:$WEB_PORT"
echo "    API:   http://localhost:4000/health"
echo "    Logs:  tail -f $LOG_DIR/*.log"
echo
echo "    Stop + rewind: ./reset-demo.sh"
