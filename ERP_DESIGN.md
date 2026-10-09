# ERP Accounting Software: Design Notes

Last updated: 2026-10-09
Status: **Skeleton done. First table (`clients`) built and tested.**

---

## 1. How we work together

- **No code until both of us confirm.** Discuss first, code second.
- Build in **small pieces**, one at a time, carefully.
- **Each piece is a full vertical slice:** its screen, its UI, its functions, its API, and its database part, all for that one piece, before moving to the next.
- Every piece of code is reviewed **line by line** with the owner before it is added.
- Ask questions **one at a time**. If the owner already has schema ideas or logic, ask for them first.
- Keep this file updated after each decision so progress is never lost.

## 2. Project goal

An **enterprise-grade, intelligent ERP accounting system for big companies**, sold by the developer to Clients.

- Multi-tenant from day one (Clients must never see each other's data).
- Strict accounting integrity, audit trail and approvals.
- Automation / "intelligent" features: **to be discussed later in depth**. We keep the data clean and event-friendly so they can be added without rework.

## 3. Target tech stack

| Layer | Tool |
|---|---|
| Frontend | React + Vite, TypeScript, Tailwind CSS |
| Backend | Node.js + Express, TypeScript |
| Database | PostgreSQL |
| ORM + migrations | Drizzle ORM + drizzle-kit |
| Validation | Zod (shared with Drizzle through drizzle-zod) |
| Money | decimal.js in code, `NUMERIC` in the database. **Never float.** |
| Frontend data | TanStack Query, TanStack Table |
| Forms | React Hook Form + Zod |
| Auth | **Better Auth** (chosen 2026-10-09; package installed, not yet configured) |
| Background jobs | pg-boss |
| Testing | Vitest |
| Reports | PDF (pdfmake or puppeteer) + Excel export (exceljs) |

**Database skills to use:** transactions (ACID), constraints, triggers, indexes, views, Row Level Security (RLS), audit logging.

**DevOps basics:** Git + GitHub, Docker, deploy (VPS / Railway / Render), `.env` and secrets, logging, backup/restore.

**Auth research note:** Lucia is deprecated (March 2025) and is now a learning resource only. Its project is part of Better Auth (Sept 2025). Passport and Supabase Auth remain options.

## 4. Structure (agreed)

```
Platform (the developer)
  └── Client (the owner who buys the software)
        ├── Users (staff)
        └── Companies
              └── Branches
                    └── Fiscal Years
                          └── Transactions
```

- **Platform (developer):** has its own admin area to create and manage Clients.
- **Client = the owner.** Exactly **one owner per Client**. Only the developer can transfer ownership, from the admin area, after verifying the request with the Client.
- **Users** are everyone else who logs in (accountants, managers, auditors and so on).
- Initial login entry: two entry points, **Developer** and **Client**. After a successful Client sign-in, the user-level access stage follows (see open questions).

## 4a. Login screens (decided)

- **The public login page shows only the Client login.** It has no link, button or mention of the Developer login.
- **Developer (Platform) login lives on a separate address** (for example `admin.yourapp.com`) that nothing links to.
- **2FA is required** for every Platform login.
- The admin page has **no sign-up and no password-reset link**, rate-limits wrong attempts, and gives the **same "invalid credentials" message** for every failure.
- **Server-side enforcement:** every admin API route rejects anyone who is not a Platform admin, whatever page they came from. Hiding the page is only the first layer.
- **IP allowlist:** not now (could lock the developer out if their address changes). Can be added later.
- **Login page design:** the owner supplied a `LoginPage.tsx` mockup (brand name RUDRABIZ, dark and gold split screen). Not added to the project yet. Needed changes: client code field for Client login, `lucide-react`, routing, and a real Better Auth sign-in instead of the placeholder.
- **Platform admins: just the developer for now.** The account is created by a one-time setup command. No admin-management screen yet (a team can be added later).
- **Admin 2FA: authenticator app (TOTP).** Free, no SMS or email needed.
- **Admin password reset:** done by a command run on the server, so the admin page needs no email sending.
- **Everything free while developing:** open-source stack, local PostgreSQL, emails printed to the server log (or a local mailbox tool) instead of really sent. Real email sending and hosting use free tiers until launch.
- **Still open:** how Client and User password reset works (needs email sending, later).

## 5. User levels (where a user can work)

| Level | Access |
|---|---|
| Client level | All companies, all branches |
| Company level | One company, all its branches (including future ones) |
| Branch level | One branch only |

The Client owner is special: billing, whole-account control, managing client-level users. Client-level users are staff with all-company access but without the owner's extra powers.

## 6. Roles and permissions (what a user can do)

- A **role** is separate from the **level**. Level = where. Role = what.
- **Each Client creates its own roles**, choosing which tabs and actions each role gets.
  - Example: a Viewer sees only the Reports tab. An Accountant sees Transactions and Reports.
- **UI hides** what a role cannot use, **and the server enforces the same rules** (same role-to-permission list drives both). The UI is convenience; the server is the real lock.
- **Protected rules** exist that **no custom role can override**. Exact list to be decided. Starting suggestion:
  - Posted transactions can never be edited or deleted (only reversed).
  - Everything is audit-logged.

## 7. Master data

- **All master tables are company level, not branch level** (chart of accounts, customers, vendors, items, tax rates, and so on).
- **Branch-level users have read-only access to master data.** Only company-level and client-level users create or change it.
- **Bank accounts** are company-level records, with a **list of branches allowed to use each one**. A branch user only sees bank accounts assigned to their branch.

## 8. Fiscal years

- Fiscal year **dates are set once per company**.
- Each branch still has **its own fiscal year record**, so branches can be opened and closed separately.

## 9. Branches

- **Every company always has at least one branch.** A default branch is created automatically.
- The UI hides branch pickers, branch columns and branch-level user options until a second branch is added.

## 10. Branch accounting and inter-branch transfers

- **Every branch must balance on its own books**, not just the company as a whole.
- A transfer between branches (for example, Head Office sends cash to Pokhara) is **one journal voucher** entered by a company-level accountant. Branch-level users never enter these.
- The **branch is recorded on each line** of a voucher, so one voucher can contain lines from many branches.
- **The system adds the inter-branch lines automatically.** The accountant enters only the real lines. The balancing lines are shown clearly before posting for confirmation.
- **One shared "Inter-Branch Current Account" per company.** Each inter-branch line records which other branch it is against. At company level it nets to zero.
- Rule per voucher: for **each branch**, total debit = total credit.

Example (Head Office sends Rs. 10,000 cash to Pokhara):

| Branch | Account | Debit | Credit | Added by |
|---|---|---|---|---|
| Pokhara | Cash in Hand | 10,000 | | accountant |
| Pokhara | Inter-Branch Current (against Head Office) | | 10,000 | system |
| Head Office | Inter-Branch Current (against Pokhara) | 10,000 | | system |
| Head Office | Cash in Hand | | 10,000 | accountant |

## 11. Document (voucher) numbering

- **Separate running sequence for each branch, in each fiscal year.**
- A voucher that touches **more than one branch** uses a **company-level sequence** instead, so branch sequences never have gaps or foreign vouchers.
- **Custom numbering with a full format template**, using parts such as `{BRANCH}`, `{TYPE}`, `{FY}`, `{SEQ:5}`. Example: `PKR/JV/83-84/00001`. The exact list of parts is to be decided.
- **One template per voucher type, for the whole company.** Only company-level and client-level users can change it.
- **Parked default (not yet confirmed):** the number is assigned **when the voucher is posted**, not when the draft is created, so posted vouchers have no gaps.

## 12. Localization

**On discussion.** Candidate: Nepal (VAT 13%, NPR, Bikram Sambat dates, fiscal year Shrawan to Ashad, VAT/TDS support). Must be decided before the schema is finalized because it affects the database design.

## 12a. Clients table (BUILT and tested)

Migrations: `backend/drizzle/0000_create_clients.sql` (table, enum, constraints) and `0001_clients_protect_triggers.sql` (code can never change; clients can never be deleted or truncated). Tested on PostgreSQL 16 with 28 cases (8 accepted, 20 refused by the right rule).

- **Login identity:** a Client or User signs in with **client code + email + password**. The code says which client they belong to, so one person can work for two clients.
- **Fields for the first version:** name, status (active / suspended / closed), client code (unique), phone, email, notes, created date.
- **Client code rules:** lowercase letters, digits and single hyphens, 3 to 40 characters, unique, **cannot be changed after creation**. Names are *not* unique.
- **How the code is chosen:** the developer types it when creating the client in the admin area. The system suggests one from the name, and if it's taken, shows an error and suggests another (like `abc-traders-2`).
- **Plans:** a separate `plans` table (limits and price) comes later. A plan column is added to `clients` after that table exists.
- Phone and email are optional text. Notes are internal to the developer, never shown to the client.
- **Next small piece, after the basics work:** license limits (max companies, branches, users), subscription start / expiry / grace period, contact details.
- **Can wait:** plan tier, billing history, branding, country and timezone.
- The owner's login lives in the auth system. The clients table only points to the owner (keeps "exactly one owner" easy to enforce).
- Clients are **never deleted**, only marked closed.

## 13. Open questions

1. Login: confirm exactly what the stage after Client sign-in looks like (one real login with a scope choice, or separate credentials per level).
2. ~~Auth library~~ Decided: Better Auth. Still open: how it maps to Platform / Client / User logins.
3. Localization decisions (section 12).
4. Final list of protected rules (section 6).
5. Voucher number timing: at posting (default) or at draft.
6. Multi-currency, and dimensions on lines (cost centers, projects, departments).
7. ID style: random UUID v4 or time-ordered v7. Human-readable numbers on documents.
8. What goes on the first tables (`clients`, `companies`, and so on): legal vs display name, base currency rules, audit fields, soft delete.
9. What "intelligent" features should come first.
10. Where the project lives: this chat's workspace or the owner's computer.

## 14. Next steps

1. ~~Project skeleton~~ done.
2. ~~First table, `clients`~~ done.
3. Continue down the structure: users, companies, branches, fiscal years, chart of accounts, journal vouchers.
