import styles from "./page.module.css";

type Order = {
  id: number;
  user_id: number;
  status: string;
  total_cents: number;
  created_at: string;
};

const API_URL = process.env.API_URL ?? "http://localhost:4000";

async function fetchOrders(userId: number): Promise<Order[]> {
  const res = await fetch(`${API_URL}/orders?userId=${userId}`, {
    cache: "no-store",
  });
  if (!res.ok) {
    throw new Error(`API ${res.status}`);
  }
  const data = (await res.json()) as { orders: Order[] };
  return data.orders;
}

export default async function Home({
  searchParams,
}: {
  searchParams: Promise<{ userId?: string }>;
}) {
  const { userId: userIdParam } = await searchParams;
  const userId = Number(userIdParam) || 1;
  const orders = await fetchOrders(userId);

  return (
    <main className={styles.main}>
      <h1>Orders</h1>
      <form className={styles.form}>
        <label htmlFor="userId">User ID</label>
        <input
          id="userId"
          name="userId"
          type="number"
          min={1}
          defaultValue={userId}
        />
        <button type="submit">Load</button>
      </form>

      <p className={styles.meta}>
        Showing {orders.length} orders for user {userId}
      </p>

      <table className={styles.table}>
        <thead>
          <tr>
            <th>ID</th>
            <th>Status</th>
            <th>Total</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          {orders.map((o) => (
            <tr key={o.id}>
              <td>{o.id}</td>
              <td>{o.status}</td>
              <td>${(o.total_cents / 100).toFixed(2)}</td>
              <td>{new Date(o.created_at).toLocaleString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
