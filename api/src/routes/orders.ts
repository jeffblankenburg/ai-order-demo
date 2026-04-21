import type { FastifyInstance } from "fastify";
import { pool } from "../db.js";

export async function ordersRoutes(app: FastifyInstance) {
  app.get("/orders", async (req, reply) => {
    const userId = Number((req.query as { userId?: string }).userId);
    if (!Number.isInteger(userId) || userId <= 0) {
      return reply.code(400).send({ error: "userId query param required" });
    }

    const { rows } = await pool.query(
      "SELECT id, user_id, status, total_cents, created_at FROM orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT 100",
      [userId]
    );
    return { orders: rows };
  });
}
