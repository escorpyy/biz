import { sql } from "drizzle-orm";
import { check, pgEnum, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const clientStatus = pgEnum("client_status", ["active", "suspended", "closed"]);

export const clients = pgTable(
  "clients",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    code: text("code").notNull().unique(),
    name: text("name").notNull(),
    status: clientStatus("status").notNull().default("active"),
    phone: text("phone"),
    email: text("email"),
    notes: text("notes"),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    check(
      "clients_code_format",
      sql`${t.code} ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and length(${t.code}) between 3 and 40`,
    ),
    check("clients_name_not_blank", sql`length(btrim(${t.name})) > 0`),
  ],
);
