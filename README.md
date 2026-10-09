# ERP Accounting Software

Enterprise accounting system. See [ERP_DESIGN.md](ERP_DESIGN.md) for every decision made so far.

**Status:** project skeleton only. No tables and no accounting logic yet.

## Structure

- `backend/`: Node.js + Express + TypeScript, Drizzle ORM, PostgreSQL
- `frontend/`: React + Vite + TypeScript + Tailwind CSS

## Run it

You need Node.js 22+ and a PostgreSQL database.

```bash
# Backend
cd backend
cp ../.env.example .env      # then edit DATABASE_URL
npm install
npm run dev                  # http://localhost:4000/health

# Frontend (second terminal)
cd frontend
npm install
npm run dev                  # http://localhost:5173
```

`GET /health` returns `{"status":"ok","database":"connected"}` when the database is reachable, and a 503 with `"unreachable"` when it is not.

## Useful commands (backend)

- `npm run typecheck` checks the types
- `npm test` runs Vitest
- `npm run db:generate` / `npm run db:migrate` run Drizzle migrations (once tables exist)

## Working rules

No code is added until it has been discussed and agreed. Tables are added one at a time, reviewed line by line.
