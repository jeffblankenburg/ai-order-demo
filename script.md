# Script — 45-minute version

Two-host conversational format (Jay = host, Jeff = presenter). Demo runs live in VS Code; this script wraps dialogue around the three Copilot Chat prompts from `DEMO_RUNBOOK.md`:

1. **Build** — `/orders/status/:id` endpoint
2. **Connect** — custom span on the new endpoint
3. **Troubleshoot** — "is anything slow on orders-api?"

Time markers are cumulative. Stage directions in `(parentheses)`. Prompts to read verbatim are in `> blockquotes`.

---

## 0:00–5:00 — COLD OPEN

**Jay:**
Hey everyone, welcome. Before we get into anything — I want to do a quick experiment. Look at your taskbar right now. How many browser tabs do you have open? Count them.

(pause)

I have… 27. That's a problem, right? And I bet I'm not even close to the highest in this room.

Jeff, I want to start here. Why do developers end up with 27 tabs?

⸻

**Jeff:**
Because every tool we use lives somewhere else. Code is in the editor. Logs are in one dashboard. Traces are in another. Tickets are in a third. Documentation is in a fourth. And we just kind of… accept that as how the job works.

⸻

**Jay:**
And every one of those tabs is a context switch.

⸻

**Jeff:**
Right. And here's the thing I want everybody to take away from today:

Developers don't hate debugging. They hate context switching.

Debugging is interesting. Debugging is the part where you actually learn something about your system. The part that's exhausting is bouncing between five tools just to assemble the picture in your head.

⸻

**Jay:**
So is the answer "better dashboards"?

⸻

**Jeff:**
No. The answer is: don't leave the editor at all.

For the next 40 minutes, I'm going to build a feature, instrument it, ship it, and troubleshoot a real production problem. And I'm not going to open a single browser tab.

⸻

**Jay:**
No browser. The whole demo.

⸻

**Jeff:**
The whole demo. Watch what that feels like.

---

## 5:00–8:00 — SETUP

**Jay:**
Alright — so what are we actually building?

⸻

**Jeff:**
A small order processing API. Real boring on purpose — it's a Fastify service in TypeScript, talking to Postgres. There's a list endpoint, an order detail endpoint, and we're going to add a third one live.

The reason I picked something this ordinary is because this is where these problems actually live. Not in the flashy AI startup. In the everyday backend nobody talks about.

⸻

**Jay:**
And the tools?

⸻

**Jeff:**
Three pieces. VS Code, that's where I live. GitHub Copilot in agent mode — that's the AI doing the work. And Dynatrace, which is going to give me the production observability picture.

The thing that ties them together is something called MCP — the Model Context Protocol. It's how Copilot can talk directly to Dynatrace, inside my editor, without me ever opening their UI.

⸻

**Jay:**
So Copilot can pull production data into the chat?

⸻

**Jeff:**
That's exactly it. And once you've seen it, going back feels broken.

⸻

**Jay:**
Alright, let's see it.

(Jeff switches to VS Code, full-screen.)

---

## 8:00–18:00 — BUILD BEAT

### Frame the moment (8:00–9:30)

**Jeff:**
Okay — so this is the project. `api/src/routes/orders.ts` — that's the file that has all the order endpoints. Right now there's `GET /orders`. I want to add an endpoint that returns just the *status* of an order — for a fulfillment service that doesn't need the whole record.

Normally I'd start typing. Today I'm going to ask Copilot to do it.

⸻

**Jay:**
Agent mode — what's the difference from regular Copilot?

⸻

**Jeff:**
Regular Copilot is autocomplete. Agent mode is "go figure it out." It can read multiple files, edit multiple files, run commands, and check its own work. I describe what I want; it figures out the steps.

### Prompt #1 — the new endpoint (9:30–13:00)

(Jeff opens Copilot Chat, types verbatim:)

> Add an `/orders/status/:id` endpoint to the Fastify API in `api/src/routes/orders.ts`. It should return the `status` field of a single order by ID, or 404 if not found. Also write a test.

(Copilot plans, edits, runs.)

⸻

**Jay:**
What's it doing right now?

⸻

**Jeff:**
It's reading the file to see how the other endpoints are written. It wants to match the style — same validation pattern, same error shape. That's the part that used to take me ten minutes.

(Pause as Copilot finishes.)

There it is. New route, 404 fallback, and it wrote a test alongside it.

### Verify (13:00–15:00)

(Jeff switches to integrated terminal.)

```bash
curl http://localhost:4000/orders/status/1
```

(Returns `{"id":1,"status":"paid"}` or similar.)

⸻

**Jay:**
That's it?

⸻

**Jeff:**
That's it. And here's the part I want to call out — *I never left this window*. Normally, right here, I'd have flipped to the Fastify docs to remember the route signature. Or I'd have opened ChatGPT in a tab. I didn't. The work happened where the work lives.

⸻

**Jay:**
Count: zero new tabs.

⸻

**Jeff:**
Zero new tabs.

### Reflect (15:00–18:00)

**Jay:**
Quick question — what if Copilot writes something wrong? Does that ever happen?

⸻

**Jeff:**
All the time. And I think that's worth being honest about. Sometimes it'll hallucinate a field name. Sometimes it'll grab the wrong file. The skill isn't "trust the AI" — it's "review the AI." But the diff is small enough to review fast, and I'm reading code in the same editor I'd be writing it in. It's not a black box.

⸻

**Jay:**
So this isn't really about writing code faster.

⸻

**Jeff:**
That's the thing. Writing code isn't the bottleneck anymore. Understanding what the code does once it's running — that's where developers actually spend their time. Which brings us to the next part.

---

## 18:00–28:00 — CONNECT BEAT

### Frame the moment (18:00–20:00)

**Jeff:**
Okay — I have a working endpoint. If I were going to ship this and walk away, I'd be flying blind. I have no idea how it performs in production, no idea if it's even being called. So step two: instrument it.

⸻

**Jay:**
And this is usually where things get painful, right?

⸻

**Jeff:**
Historically, yes. Standing up observability is a project. You pick a vendor, you wire up an agent, you configure exporters, you fight with environment variables for a day. I'm going to show you what that actually looks like now.

(Jeff opens `api/src/telemetry.ts`, scrolls slowly.)

This file. That's the entire OpenTelemetry setup for this service. Eighty lines, mostly comments. It exports traces and metrics to Dynatrace. That's it.

⸻

**Jay:**
Eighty lines for full observability?

⸻

**Jeff:**
That's the modern world. OTel is a standard now. The hard part used to be the wiring; the hard part now is *what you do with the data*.

### Prompt #2 — instrument the new endpoint (20:00–24:00)

**Jeff:**
But auto-instrumentation only gets me so far. I want a custom span around my new endpoint, so I can find it specifically in traces.

(Jeff types in Copilot Chat:)

> Add a custom span to the new `/orders/status/:id` endpoint so I can see it in Dynatrace traces. Call the span `orders.status.lookup`.

(Copilot edits.)

⸻

**Jay:**
And it just… knows how to do that?

⸻

**Jeff:**
It knows the OTel API because it's reading my existing telemetry file. It can see I'm using the Node SDK and the standard tracer. So it grabs the tracer and wraps the handler. (points at the diff) Right there.

Most demos stop here. "Look, it works locally."

But the hard part is what happens when something goes wrong, and you have no idea where to look. Which is *always*.

⸻

**Jay:**
And that's where the tabs usually come in.

⸻

**Jeff:**
That's where the 27 tabs come in. Logs in one tab. Traces in another. The query plan view in a third. Slack with the on-call engineer in a fourth. By the time you've reconstructed what happened, you've forgotten what you were originally building.

So I want to show you the part that actually matters. Watch what happens when I check on this thing.

---

## 28:00–41:00 — TROUBLESHOOT BEAT

### "Let me just check prod" (28:00–30:00)

**Jeff:**
Before I move on to anything else, I always check prod health. It's a habit. So let me just do that.

### Prompt #3 — check latency (30:00–33:00)

(Jeff types in Copilot Chat:)

> Use Dynatrace to tell me if anything's slow on the orders-api service in the last five minutes. Show me the p95 latency and compare it to what you'd expect. If there is a latency issue, please explain why and implement a solution.

(Copilot calls MCP. Streams a response.)

⸻

**Jay:**
What's it doing now?

⸻

**Jeff:**
It just made a call to Dynatrace through MCP. Asked for latency on the orders-api service. And it's coming back with — there. p95 on `GET /orders` is around 155 milliseconds. Which is *slow* for a simple list endpoint with a few thousand rows.

⸻

**Jay:**
And that's real data from Dynatrace.

⸻

**Jeff:**
Real data. In my editor.

There it is. `pg.query` — a SELECT against the `orders` table. About 150 of the 155 milliseconds is in this one query. So it's not the framework, it's not the network, it's the database.

⸻

**Jay:**
So now the question is why.

⸻

**Jeff:**
And there's the diagnosis. The query filters on `user_id`, but there's no index on `user_id`. So Postgres is doing a sequential scan of the entire `orders` table. Every request.

(Copilot returns updated p95.)

⸻

**Jeff:**
Five to fifteen milliseconds. That's a 10–20× improvement, in the time it took to type a sentence.

(Pause. Let it land.)

### The browser reveal (40:30–41:00)

---

## 41:00–45:00 — CLOSE

**Jay:**
So if you had to land this in one sentence — what changed?

⸻

**Jeff:**
The gap closed. Code, observability, and the AI agent — they're all in the same room now. I don't context-switch to debug anymore. Debugging is part of how I write code.

⸻

**Jay:**
And the thesis from the top —

⸻

**Jeff:**
Developers don't hate debugging. They hate context switching. Today we removed the context switching.

⸻

**Jay:**
One tab. Five seconds.

⸻

**Jeff:**
One tab. Five seconds.

If you've ever spent an afternoon bouncing between five tools just to figure out why one endpoint got slow — this is a much better way to work. The tools are real, they're available today, and the wiring is in the description below this video.

⸻

**Jay:**
We've got a few minutes for questions. (Hand off to Q&A.)

---

## Pacing notes

- Total: ~45 min, of which ~12 min is live demo and ~33 min is dialogue + reflection.
- If running long: cut the BUILD reflect section (15:00–18:00) and the CONNECT reflect section (25:00–28:00). Recover ~6 min.
- If running short: extend the cold-open audience interaction, or add a third trace drill-down ("show me the user IDs hitting this endpoint most") before the fix.
- Hard floor on the troubleshoot beat: don't compress under 10 min. The hero scene needs room to breathe.
