// OTel must load first — it patches Node's module loader before
// fastify and pg are imported, otherwise auto-instrumentation misses them.
import "./telemetry.js";

import Fastify from "fastify";
import cors from "@fastify/cors";
import { ordersRoutes } from "./routes/orders.js";

const app = Fastify({ logger: true });

await app.register(cors, { origin: true });

app.get("/health", async () => ({ ok: true }));

await app.register(ordersRoutes);

const port = Number(process.env.PORT ?? 4000);
app.listen({ port, host: "0.0.0.0" }).catch((err) => {
  app.log.error(err);
  process.exit(1);
});
