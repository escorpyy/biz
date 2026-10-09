import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import { config } from "../config.js";

export const pool = new Pool({
  connectionString: config.DATABASE_URL,
  connectionTimeoutMillis: 3000,
});

export const db = drizzle(pool);

export async function checkDatabase(): Promise<boolean> {
  try {
    await pool.query("select 1");
    return true;
  } catch {
    return false;
  }
}
