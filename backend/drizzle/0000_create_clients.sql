CREATE TYPE "public"."client_status" AS ENUM('active', 'suspended', 'closed');--> statement-breakpoint
CREATE TABLE "clients" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" text NOT NULL,
	"name" text NOT NULL,
	"status" "client_status" DEFAULT 'active' NOT NULL,
	"phone" text,
	"email" text,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "clients_code_unique" UNIQUE("code"),
	CONSTRAINT "clients_code_format" CHECK ("clients"."code" ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and length("clients"."code") between 3 and 40),
	CONSTRAINT "clients_name_not_blank" CHECK (length(btrim("clients"."name")) > 0)
);
