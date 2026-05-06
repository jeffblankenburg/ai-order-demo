# Script — 45-minute version

Two-host conversational format (Jay = host, Jeff = presenter). Demo runs live in VS Code; this script wraps dialogue around the three Copilot Chat prompts from `DEMO_RUNBOOK.md`:

1. **Build** — `/orders/status/:id` endpoint
2. **Connect** — custom span on the new endpoint
3. **Troubleshoot** — "is anything slow on orders-api?"

Time markers are cumulative. Stage directions in `(parentheses)`. Prompts to read verbatim are in `> blockquotes`.

---

## Intro - 0:00 - 2:00

**Jay – Intro**

Hey everyone, welcome. I'm Jay Gurbani, Partner Architect at Dynatrace. My job is basically making sure Dynatrace and the Microsoft developer stack play well together -- so developers can stay in their flow and stop bouncing between multiple tools and windows. And with me is Jeff --

**Jeff - (Intro)**

**Jay – Preamble** 
- Today we're going to talk about something I think every developer has felt -- that constant back-and-forth between writing code and trying to figure out what it's actually doing in production.
 - We will keep this very open ended and have conversation with Jeff our expert
- We're going to cover the full loop – Jeff is going to build, debug it why the new service is slow, ad we’ll have CoPilot fix -- validate it


## 2:00–5:00 — Developer Pain Points

**(Jeff to begin sharing his screen)**

⸻

**Jay:**
Before we start -- I want to do look at what you have on your screen. How many windows do you have open? Not just your editor -- count everything. Your terminals, your dashboards, your Slack/Teams, your ticket board, your docs.

⸻

**Jeff** – (Setup to talk about developer pain points)
- Why are so many windows open?
- Context switching 
- Debugging?

⸻

**Jay** – So is the answer better dashboards or better alerts?

⸻

**Jeff** The answer is: don't leave the editor at all.
- For the next 40 minutes, I'm going to build a feature, instrument it, ship it, and troubleshoot a real production problem. And I'm not going to open a single browser tab — except for one five-second moment at the very end, just so you can see what I would normally have been staring at the whole time.


⸻

**Jeff:**
Because every tool we use lives somewhere else. Code is in the editor. Logs are in one dashboard. Traces are in another. Tickets are in a third. Documentation is in a fourth. And we just kind of… accept that as how the job works.

⸻

**Jay:**
And every one of those tabs or windows is a context switch for you.

⸻

**Jeff:**
Right. And here's the thing I want everybody to take away from today:

Developers don't hate debugging. They hate context switching.

Debugging is interesting. Debugging is the part where you actually learn something about your system. The part that's exhausting is bouncing between five tools just to assemble the picture in your head.



---

## 5:00–8:00 — SETUP

**Jay:**
Alright — so what are we actually building? What type app do you have loaded up in your IDE?

⸻

**Jeff:**
A small order processing API. Real boring on purpose — it's a Fastify service in TypeScript, talking to Postgres. There's a list endpoint, an order detail endpoint, and we're going to add a third one live.

The reason I picked something this ordinary is because this is where these problems actually live. Not in the flashy AI startup. In the everyday backend nobody talks about.

⸻

**Jay:**
What tools are you using today to buld your app?

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

⸻

**Jay:**
Berfore we move to your app, can we talk about MCP setup you have with Dynatrace for a bit? How is it setup?  What permissions you've setup in Dynatrace?  

⸻

**Jeff:**
(Talk a about the scopes you gave it at high level.  Don't talk about MCP tools etc yet.  There's a dialogue later about it)


---

## 8:00–18:00 — BUILD BEAT

### Frame the moment (8:00–9:30)

**Jay:**

Let’s now talk about what we want to have CoPilot add to this app now.  

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
While CoPilot is doing its magic.  Let me ask you question.  

How do you think about this from a team perspective? If I'm a lead and my devs are using Copilot to write code all day -- how do I know the code is good?
⸻

**Jeff:**
(Smart response)


⸻
**Jeff:**
(Going back to CoPilot output and reviewing what it did so far)
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
## Reflect (15:00-18:00)

**Jay:** Quick question -- and I think a lot of people watching are thinking this too. What about accountability? Copilot just wrote a bunch of code. What if it writes something wrong?

⸻

**Jeff:** All the time. And I think that's worth being honest about. Sometimes it'll hallucinate a field name. Sometimes it'll grab the wrong file. The skill isn't "trust the AI" -- it's "review the AI." But the diff is small enough to review fast, and I'm reading code in the same editor I'd be writing it in. It's not a black box.

⸻

**Jay:** So this isn't really about writing code faster.

⸻

**Jeff** That's the thing. Writing code isn't the bottleneck anymore. Understanding what the code does once it's running -- that's where developers actually spend their time. Which brings us to the next part.

⸻

**Jay:** And that's actually where Dynatrace fits into this AI code generation picture, right? If AI is writing more code faster, you need a way to understand what all that code is actually doing in production.

⸻

**Jeff:** Exactly. The more code AI generates, the more important observability becomes. You can't review what you can't see. So let's see it.


## 18:00–28:00 — CONNECT BEAT (Observability)

### Frame the moment (18:00–20:00)

**Jay:**  Are we ready to ship this service to production??  But wait, before we do that, we should instrument this app first, no?

⸻

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

⸻

**Jay:** And this is a good moment to zoom out for a second — because when Jeff says "OTel," he's talking about OpenTelemetry, which is an open-source, vendor-neutral standard for collecting traces, metrics, and logs. It's become *the* standard. And Dynatrace is one of the top contributors to that project — we're not just compatible with it, we actively help build it.

⸻

**Jeff:** Which is why this setup is so clean. I'm using the standard OTel Node SDK — nothing Dynatrace-proprietary in my application code. If I ever wanted to send this telemetry somewhere else, I change an exporter URL. That's it.

⸻

**Jay:** Right, and that's the OTel path — full manual control, you decide exactly what spans and metrics to create, and it's completely portable. But Dynatrace *also* has OneAgent, which is a different approach. OneAgent is our proprietary runtime agent — you deploy it at the host or container level and it automatically discovers and instruments everything. No code changes at all. It gives you things that OTel auto-instrumentation can't easily do on its own — code-level method hotspots, CPU and memory profiling, automatic dependency mapping across your entire stack. It sees the full topology.

⸻

**Jeff:** So the way I think about it: OTel is "I want to instrument *this specific thing* and I want portability." OneAgent is "I want deep, automatic visibility across *everything* without touching code."

⸻

**Jay:** Exactly. And the key thing is you're not choosing one or the other — you can run both. OneAgent gives you the broad automatic baseline, and then you layer in OTel for custom business-specific spans and metrics, like exactly what Jeff is about to do. Dynatrace ingests both natively and correlates them together. You're never locked into a proprietary SDK.

### Prompt #2 — instrument the new endpoint (20:00–24:00)

**Jeff:**
But auto-instrumentation only gets me so far. I want a custom span around my new endpoint, so I can find it specifically in traces.

(Jeff types in Copilot Chat:)

> Add a custom span to the new `/orders/status/:id` endpoint so I can see it in Dynatrace traces. Call the span `orders.status.lookup`.

(Copilot edits.)

⸻

**Jay:**
Wow...And it just… knows how to do that?

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

(We both have a dialog and explain the Copilot <-> Dynatrace remote MCP a bit more)

**Jay:**
What's CoPilot doing here with MCP to Dynatrace?

⸻

**Jeff:**
It just made a call to Dynatrace through MCP. Asked for latency on the orders-api service. And it's coming back with — there. p95 on `GET /orders` is around 155 milliseconds. Which is *slow* for a simple list endpoint with a few thousand rows.

⸻

**Jay:** 

So just to be clear -- what's actually happening under the hood here? Copilot is calling out to Dynatrace's API?

⸻

**Jeff:**
(Explain a little bit how MCP works)

Yeah -- the MCP server acts as a bridge. Copilot sends a tool call to the MCP server, the server translates that into a Dynatrace API query -- in this case a DQL query against our trace data in Grail -- and sends the results back. Copilot then interprets those results in the context of what I asked. So I don't need to know DQL syntax. I just ask a question in English.

⸻

**Jay:**
And that's real production data from Dynatrace.

⸻

**Jeff:**
Real production data. In my editor.  No extra windows, no context switching.

⸻
**Jay:** (interrupts) I want to pause here for a second because I think people might miss what just happened. Copilot is having a conversation with Dynatrace through MCP -- back and forth. It's not just a one-shot query. It's reasoning about the data.

⸻

**Jeff:** Right -- and that's the key difference from just having a dashboard open. The AI is interpreting the data for me and connecting it to the context of what I'm working on.


⸻
(Going back to CoPilot to hopefully it point out the database being root cause of the slowness??)

**Jeff:**
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

### Reflect ROI Question

**Jay:** Let me ask you something a lot of dev teams are wrestling with. As everyone tries to adopt AI coding tools, but a lot of leaders tell me: "I'm not sure we're getting the ROI." What would you say to that?

⸻

**Jeff:** I'd say the ROI isn't in the code generation -- it's in the investigation loop. Writing code 20% faster is nice. But cutting a two-hour production investigation down to two minutes? That's where the real value is. And that requires connecting the AI to your production data, which is what MCP does. Without that connection, your AI coding assistant is just a very fast typist. With it, it's an actual co-pilot that can see your system.


---

## 41:00–45:00 — CLOSE

**Jay:** Let me zoom out. We showed three things today: building a feature with Copilot, instrumenting it with OpenTelemetry, and troubleshooting it with Dynatrace -- all without leaving VS Code. Then we took it further with agent mode doing the investigation autonomously. But this story goes beyond just this demo, right?

⸻

**Jeff:** Oh yeah. Think about the full lifecycle. You're building in VS Code with Copilot -- that's your inner loop. You push to GitHub, GitHub Actions runs your CI/CD pipeline, deploys to Azure. Dynatrace is watching everything in production -- and now, with MCP, that production insight feeds right back into your editor.
It's a closed loop. Build, deploy, observe, fix -- all connected.

⸻

**Jay:** And this works whether you're running .NET on Azure App Service, Node on Azure Container Apps, Java on AKS -- whatever your stack is.

⸻

**Jeff:** Right. Dynatrace doesn't care about your language or framework. And with OTel being the standard, the instrumentation is portable too.

⸻

**Jay:** What about teams that are building AI into their apps -- using Microsoft Foundry to deploy models for things like classification, recommendation, summarization?

⸻

**Jeff:** That's getting really important. More and more apps are embedding LLM calls -- whether it's GPT, Llama, Mistral or Anthropic whatever you're deploying through Foundry. And those calls need observability just like any other service call. Dynatrace captures token usage, latency, error rates on those LLM spans. So if your Foundry model starts timing out or returning bad results, you see it the same way you'd see a slow database query. And Copilot agent mode can investigate those too, through the same MCP connection.

⸻
**Jay:** So the same workflow we showed today -- agent mode pulling Dynatrace data to diagnose a problem -- that works for AI features too.

⸻

**Jeff:** Exactly. The agent doesn't care whether it's looking at a database span, an HTTP call, or an LLM invocation. It's all in Dynatrace, it's all available through MCP.

⸻

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

**Jay:** If any of you want to try this yourself:
- The Dynatrace MCP server is fully GA now and available within your Dynatrace environment — as Jefff showed earlier you can connect to it via VS Code in minutes
- Start a free Dynatrace trial to connect your own apps

Thanks you for watching, everyone. And Jeff thanks for building and breaking things live. Always a good time.

⸻

**Jeff:** Always. Thanks everyone.


---

## Pacing notes

- Total: ~45 min, of which ~12 min is live demo and ~33 min is dialogue + reflection.
- If running long: cut the BUILD reflect section (15:00–18:00) and the CONNECT reflect section (25:00–28:00). Recover ~6 min.
- If running short: extend the cold-open audience interaction, or add a third trace drill-down ("show me the user IDs hitting this endpoint most") before the fix.
- Hard floor on the troubleshoot beat: don't compress under 10 min. The hero scene needs room to breathe.
