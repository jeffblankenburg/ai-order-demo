-- Schema
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE orders (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  status TEXT NOT NULL,
  total_cents INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- NOTE: deliberately no index on orders.user_id.
-- The demo's "slow query" scenario depends on seq scans here.
-- The fix during the demo is: CREATE INDEX ON orders(user_id);

-- Seed: 1,000 users
INSERT INTO users (email, name)
SELECT
  'user' || g || '@example.com',
  'User ' || g
FROM generate_series(1, 1000) AS g;

-- Seed: 5,000,000 orders spread across users.
-- Row count chosen so a seq-scan-by-user_id takes ~200-500ms
-- and adding the index drops it to ~10-20ms — a visible win in the demo.
INSERT INTO orders (user_id, status, total_cents, created_at)
SELECT
  1 + (random() * 999)::int,
  (ARRAY['pending','paid','shipped','delivered','cancelled'])[1 + (random() * 4)::int],
  (500 + random() * 49500)::int,
  now() - (random() * interval '365 days')
FROM generate_series(1, 5000000);

ANALYZE;

-- Force single-threaded execution so the missing-index cost is dramatic
-- and deterministic on stage. Without this, Postgres parallelizes the seq
-- scan across workers and the demo query looks fast even at 5M rows.
ALTER DATABASE orders SET max_parallel_workers_per_gather = 0;
