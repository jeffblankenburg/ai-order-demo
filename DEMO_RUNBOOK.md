# Demo Runbook — 20-minute version

What Jeff does on stage, minute by minute. Everything in "Pre-demo checklist" is one-time setup that already exists; the rest is the live performance.

---

## Pre-demo checklist (T-minus 10 minutes)

Run through in order. If any step is red, fix before going on.

- [ ] **Docker Desktop running.**
- [ ] **Run `./start-demo.sh`** — brings Postgres + API + web + load-gen up and waits until each is healthy. Prints the web URL when ready.
- [ ] **MCP up.** Command Palette → `MCP: List Servers` → `dynatrace-mcp` shows **Running**.
- [ ] **Copilot Chat in Agent mode.** Dynatrace tools visible and checked.
- [ ] **Dynatrace tab pre-loaded** in a browser, minimized. For the 5-second reveal only.
- [ ] **VS Code zoomed** to 20pt+ font. Side panel closed so chat has room.
- [ ] **Index does NOT exist yet.** Verify: `docker exec ai-order-demo-db psql -U orders -d orders -c "\d orders"` — should show no index on `user_id`. (The reset script drops it; the startup script doesn't create it.)

### What `start-demo.sh` starts for you

| Piece | Where | Log file |
|---|---|---|
| Postgres | Docker container `ai-order-demo-db` | `docker logs ai-order-demo-db` |
| API | `http://localhost:4000` | `.demo-logs/api.log` |
| Web | `http://localhost:3000` or `:3001` | `.demo-logs/web.log` |
| Load-gen | ~2 rps `curl` loop | `.demo-logs/loadgen.log` |

All four are detached and keep running after the script exits. Stop everything with `./reset-demo.sh`.

---

## 0:00–1:30 — Cold open (slides only)

**What you say:**
- "How many tabs do you have open right now?" Pause. Let them count.
- "Developers don't hate debugging. They hate context switching."
- "In the next 18 minutes, I'm going to build, ship, and troubleshoot a production app. I won't open a browser tab once — except for five seconds at the very end. Watch what that feels like."

**What you do:** End of slide 3, switch to VS Code.

---

## 1:30–5:00 — BUILD beat

The warmup. Not the show.

### Step 1 — Open the project in VS Code

Make sure `api/src/routes/orders.ts` is visible for a second, then open Copilot Chat.

### Step 2 — Prompt Copilot

In chat (Agent mode), type verbatim:

> Add an `/orders/status/:id` endpoint to the Fastify API in `api/src/routes/orders.ts`. It should return the `status` field of a single order by ID, or 404 if not found. Also write a test.

### Step 3 — Let it work

Copilot will plan → edit `orders.ts` → maybe create a test file → try to run the test. Click **Apply** on the changes.

### Step 4 — Verify in terminal

```bash
curl http://localhost:4000/orders/status/1
```

**Expected:** `{"id":1,"status":"paid"}` (or similar).

**What you say while this runs:**
- "Normally, right here, I'd flip to docs or to ChatGPT. I didn't need to. Still in VS Code."

**If Copilot writes buggy code:** accept it and fix live. That's real development and the audience respects it. Don't apologize.

---

## 5:00–8:00 — CONNECT beat

### Step 1 — Briefly show `telemetry.ts`

Open `api/src/telemetry.ts`. Scroll for 5–10 seconds.

**What you say:**
- "This is what observability costs you now. One file. That's the whole OTel setup."

### Step 2 — Instrument the new endpoint

In Copilot Chat:

> Add a custom span to the new `/orders/status/:id` endpoint so I can see it in Dynatrace traces. Call the span `orders.status.lookup`.

Let Copilot edit. Apply.

### Step 3 — Commit

Integrated terminal:

```bash
git add -A && git commit -m "add orders status endpoint with tracing"
```

**What you say:**
- "That's it. If I were deploying to Azure I'd `az containerapp update` right now. For time, I'm going to pretend we already shipped."
- "Most demos stop here — 'it works locally.' Watch what happens next."

---

## 8:00–18:00 — TROUBLESHOOT beat (the hero)

**This is the demo.** Everything before this was warmup.

### Beat 1 — "Let me just check prod" (8:00–10:00)

**What you say:**
- "Before I move on, I always check prod health. It's a habit. Let me do that now."

In Copilot Chat:

> Use Dynatrace to tell me if anything's slow on the orders-api service right now. Show me the p95 latency and compare it to what you'd expect.

**Expected:** Copilot calls MCP → returns something like "p95 on GET /orders is ~155ms, which is noticeably slow for a simple list endpoint."

**If it returns empty:**
- Check the load-gen terminal. If it died, restart it and wait 30 seconds.
- Fallback prompt: `Show me the 10 most recent traces for orders-api, sorted by duration descending.`

### Beat 2 — "Find the slow thing" (10:00–13:00)

> What's the slowest span inside those p95 traces? Show me the SQL if there is one.

**Expected:** Copilot surfaces the `pg.query:SELECT orders` span, ~150ms of the 155ms total, and shows the SQL text.

**What you say:**
- "There's the bottleneck. One query, 150 milliseconds. Why?"

### Beat 3 — Root cause + fix (13:00–15:00)

> Why is that query slow? Explain based on the query plan, then write me the migration that fixes it.

**Expected:** Copilot reasons about the missing index on `orders.user_id`, then generates:

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_id ON orders(user_id);
```

Apply.

### Beat 4 — Apply the fix (15:00–16:30)

Integrated terminal:

```bash
docker exec ai-order-demo-db psql -U orders -d orders \
  -c "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_id ON orders(user_id);"
```

**Expected:** `CREATE INDEX` in 1–3 seconds.

**What you say:**
- "One second. That's the whole fix."

### Beat 5 — Verify recovery (16:30–17:30)

In Copilot Chat:

> Is the p95 recovering now? Check the most recent traces for orders-api.

**Expected:** Copilot reports p95 is now ~5–15ms — a 10–20× drop. (Load-gen is still running, so new traces reflect the fix.)

**Pause.** Let it land. Don't rush.

### Beat 6 — The browser reveal (17:30–18:00)

**What you say:**
- "Here's the only tab I'll open the whole demo."

Alt-tab to the Dynatrace browser tab. Show the p95 chart with the visible cliff. Hold for **exactly 5 seconds**. Don't click anything.

Alt-tab back to VS Code.

**What you say:**
- "That's it. Everything else was right here."

---

## 18:00–20:00 — Close

Back to slide 3 (old world / new world).

**What you say:**
- Recap the three beats — Build, Connect, Troubleshoot.
- "One tab. Five seconds of that one tab."
- Thesis callback: "Developers don't hate debugging. They hate context switching."
- CTA + resources slide.

---

## Things that can go wrong (and what to do)

| Failure | Response |
|---|---|
| MCP server hangs or disconnects mid-demo | Don't apologize. Say "let me just look at this directly" and open the Dynatrace tab. Story still works — you're ahead of script. |
| Copilot produces nonsense code | Accept it, read it out loud, fix it live. Real development. Audience respects honesty. |
| Load-gen terminal died | You'll notice because Beat 1 returns empty. Restart it, wait 30s, fire ~10 manual curls, re-ask. |
| Index creation hangs > 5s | Drop the `CONCURRENTLY` keyword. Still ~1s. |
| Internet flakes, MCP can't reach Dynatrace | Open the Dynatrace tab, narrate the traces there. "Normally I'd do this without leaving, today we do it the old way." |
| Audio / mic / screenshare dies | Not your problem. Host handles it. |

---

## Rules of the demo

1. **No browser tabs** except the 5-second reveal.
2. **No setup commands** (`npm install`, `docker compose up`) on camera.
3. **No apologies** for small imperfections.
4. **No deep explanation of OTel wiring.** Show the file for 10 seconds, move on.
5. Every time you notice you're *about* to tab out: narrate it instead. "Normally, right here, I'd open X. I don't need to."

The restraint *is* the story.
