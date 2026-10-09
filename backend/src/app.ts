import express from "express";
import { checkDatabase } from "./db/client.js";

export const app = express();

app.use(express.json());

app.get("/health", async (_req, res) => {
  const database = await checkDatabase();
  res.status(database ? 200 : 503).json({
    status: database ? "ok" : "degraded",
    database: database ? "connected" : "unreachable",
  });
});
