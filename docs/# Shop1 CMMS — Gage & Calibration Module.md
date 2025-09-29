# Shop1 CMMS — Gage & Calibration Module (GTC) Design v0.1

**Owner:** Sean Treppa (Director of IT)  
**Date:** 2025‑09‑23  
**App Family:** Shop1 / FinishLine (Uno Platform C# + PostgreSQL)  
**Module:** Gage Tracking, Calibration, Auditing, MSA, Notifications

---

## 1) Purpose & North Star

**Goal:** Provide end‑to‑end traceability and control for measurement & test equipment (MTE) across its entire life cycle—procurement → custody → calibration → use → storage → retirement—while meeting ISO/IATF/AS/21 CFR Part 11 needs and integrating cleanly with Shop1.

**Outcomes**

- Zero surprises on due calibrations (predictive scheduling + clear dashboards)
- Fast, consistent data entry (templates, cloning, bulk tools)
- Bullet‑proof audit trails & e‑signatures
- Simple evidence production for auditors in minutes (reports, certs, histories)
- Hooks for automation (MQTT/Web API) & MES/ERP tie‑ins

---

## 2) Scope (MVP → Phase 2)

### MVP (Phase 1)

- Gage registry & life‑cycle states
- Calibration schedules & reminders (pause/resume, grace, escalation)
- Procedures library + versioning + linkage to gages
- Events & notifications (email/Graph API)
- Certificates & core reports
- Electronic signatures (Part 11‑style) + comprehensive audit trail
- Role/group security + saved views/filters + column selectors
- Gage transfers (crib ↔ dept ↔ vendor) + simple routing rules
- Templates + cloning + find/replace + dropdown list admin
- Ad‑hoc listings (any view → export)
- Archive Manager (soft‑archive + purge policies)

### Phase 2

- MSA suite (Gage R&R, Linearity, Stability) with analytics & storage
- Formula Manager (unit conversions, averages, custom math)
- Auto frequency adjustment (NCSL‑inspired) + cost curve analysis
- Drag‑and‑drop calendar + enhanced due dashboard (activities, crib, MSA)
- MQTT publisher + optional broker; Web API server + Identity Provider (OIDC)
- Crib/service request workflows (single‑step or two‑step)
- Enhanced custodians (suppliers/staff/customers) with interaction history

Out‑of‑scope (for now): vendor portal, mobile calibration app, full IoT ingestion.

---

## 3) Personas & Permissions

- **Calibration Tech**: create/execute calibration, upload results, sign.
- **Crib Manager**: transfers, custody, service requests, inventory tie‑ins.
- **Quality Engineer**: schedules, MSA studies, procedures, reports.
- **Quality Manager**: approvals, signatures, policy, audit response.
- **Auditor (read‑only)**: search, view certs, histories, e‑sigs, reports.
- **Admin**: security groups, data dictionaries, archive, integrations.

**Security Model** (group‑level): View/Edit/Create/Delete per entity; additional grants for Approve, Sign, Void, Archive, Restore, Configure, Export.

---

## 4) Key Concepts & States

### Gage (MTE)

- **Core fields:** tag_no, type, manufacturer, model, serial_no, range, resolution, accuracy, units, classification (critical/special/standard), location, status, custodian, department, process linkage (Where Used), risk level, next_due, last_cal_date, cycle, cycle_basis (days/months/use‑count), grace_policy, quarantine_flag, notes.
- **States:** *In Service*, *Due Soon*, *Past Due*, *Out for Cal*, *In Crib*, *Quarantined*, *Retired*.  
  Transitions enforce business rules (e.g., Past Due → Quarantined on use‑attempt).

### Calibration Schedule

- Fixed interval or rules‑based (usage‑count, risk, NCSL‑adjusted).  
- Pause/resume with reason + audit; recalculates next_due on resume.

### Procedure

- Versioned documents with attachments; linked to gage types or individual gages.

### Event

- Discrete log items (transfer, status change, failure, signature, schedule change).  
- All events are auditable and can trigger notifications.

### Certificate

- Immutable snapshot of results, references, signers, and conditions at time of calibration.

---

## 5) Data Model (PostgreSQL‑first; MS SQL compatible)
>
> Conventions: snake_case, lowercase, surrogate keys, FK integrity, JSONB for flexible metadata. Use citext for case‑insensitive text where helpful.

```sql
create table gage (
  gage_id           bigserial primary key,
  tag_no            text unique not null,
  gage_type_id      bigint references gage_type(gage_type_id),
  manufacturer      text, model text, serial_no text,
  range_text        text, resolution_text text, accuracy_text text,
  units             text, classification text, risk_level int default 0,
  location_id       bigint references location(location_id),
  status            text not null default 'in_service',
  custodian_id      bigint references custodian(custodian_id),
  dept_id           bigint references department(dept_id),
  where_used        jsonb default '[]',
  last_cal_date     date, next_due date,
  cycle_value       int,          -- e.g., 6
  cycle_basis       text,         -- 'months' | 'days' | 'uses'
  grace_days        int default 0,
  quarantine_flag   boolean default false,
  meta              jsonb default '{}',
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

create table gage_event (
  gage_event_id bigserial primary key,
  gage_id       bigint references gage(gage_id),
  event_type    text not null,   -- 'transfer','status_change','schedule','failure','signature','msa','calibration'
  event_time    timestamptz default now(),
  actor_id      bigint references app_user(user_id),
  details       jsonb not null
);

create table procedure_doc (
  procedure_id  bigserial primary key,
  code          text unique,
  title         text not null,
  version       text not null,
  body_md       text,            -- Markdown source
  attachments   jsonb default '[]',
  effective_on  date,
  superseded_by bigint references procedure_doc(procedure_id)
);

create table calibration (
  calibration_id bigserial primary key,
  gage_id        bigint references gage(gage_id),
  performed_at   timestamptz not null,
  performed_by   bigint references app_user(user_id),
  procedure_id   bigint references procedure_doc(procedure_id),
  environment    jsonb,         -- temp, humidity, etc.
  results        jsonb not null, -- raw points, pass/fail per step
  verdict        text not null,  -- 'pass'|'fail'|'as_found_fail_as_left_pass', etc.
  oos_flag       boolean default false,
  cert_no        text unique,
  signed_state   text default 'unsigned',
  created_at     timestamptz default now()
);

create table signature (
  signature_id  bigserial primary key,
  calibration_id bigint references calibration(calibration_id),
  step          text not null,   -- 'perform','review','approve'
  signer_id     bigint references app_user(user_id),
  signed_at     timestamptz,
  reason        text,
  esig_hash     text not null,   -- hash(user+cal+step+timestamp)
  esig_meta     jsonb
);

create table schedule_rule (
  schedule_id   bigserial primary key,
  gage_id       bigint references gage(gage_id),
  mode          text not null,      -- fixed | usage_based | ncsl
  interval_val  int,                 -- 6
  interval_unit text,                -- months/days
  usage_target  int,                 -- if usage_based
  paused        boolean default false,
  paused_reason text,
  resume_on     date,
  meta          jsonb default '{}'   -- cost params, risk bands, etc.
);

create table msa_study (
  msa_id        bigserial primary key,
  gage_id       bigint references gage(gage_id),
  type          text not null,   -- rr, linearity, stability
  config        jsonb not null,
  results       jsonb,
  created_at    timestamptz default now(),
  completed_at  timestamptz
);
```

**Indexes:** due-date, status, location, classification, next_due; partial indexes for `status in ('due_soon','past_due')`.

---

## 6) Scheduling Engine

**Inputs:** schedule_rule, last_cal_date, usage counters, risk level, NCSL policy, grace.

**Logic:**

1. Compute **base_next_due** from interval or usage.
2. Apply **NCSL adjustment** (Phase 2): shorten/extend based on consecutive passes/fails; cap by risk band.
3. Apply **grace** and **pause windows**.
4. Emit **events** on state boundary crossings (due soon, past due, resumed).

**Usage Counter Source:** manual entry, work‑order runtime, or MQTT topic (e.g., `shop1/gtc/usage/{tag_no}` with payloads `{ "count": 1 }`).

---

## 7) Formula Manager (Phase 2)

- Create named formulas with inputs/outputs and unit semantics.
- Example: `c_to_f(c) = (c * 9/5) + 32`  
- Bind to procedure steps to auto‑convert & compute verdicts.
- Versioned; per‑procedure overrides allowed.

---

## 8) MSA Suite (Phase 2)

- **R&R:** ANOVA and Range‑based methods; store raw data, summaries, charts.
- **Linearity:** bias vs reference across range; regression + plots.
- **Stability:** time‑series drift detection; SPC rules.
- Results become part of **gage history** and can influence risk/frequency.

---

## 9) Dashboards & UI (Uno + WASM)

- **Due Listing Dashboard:** tiles for *Past Due*, *Due ≤30d*, *Out for Cal*, *Quarantined*; quick filters (dept, location, classification); batch actions (print labels, email, assign).
- **Calendar (DnD):** visualize due dates; drag to propose/commit new dates (permission‑gated).
- **Gage Detail:** split‑pane—summary left; tabs right (History, Where Used, Certificates, MSA, Events). Column selectors, saved views, per‑user presets.
- **Transfers:** wizard with routing rules (single vs two‑step); batch mode from list.
- **Templates:** create/update templates; multi‑record apply; find/replace with preview.
- **Reports:** pre‑formatted gage details, cert, performance, utilization; export PDF/CSV.

---

## 10) Notifications & Automation

- **Notification Manager:** rule → channel mapping (Email/Graph API, MQTT publish, Webhook).  
- Triggers: due soon, past due, calibration created/fails, status changes, transfer events, MSA completed, signature events.
- **Digests:** daily/weekly scheduled emails with due listings per dept.
- **SMTP/Graph:** support Microsoft Graph API for O365; fallback SMTP.

---

## 11) Electronic Signatures & Audit (21 CFR Part 11‑style)

- Multi‑level signatures (perform → review → approve), unique credentials per signer, time‑stamped, reason codes, and immutable hash (stored with calibration).
- **Audit Trail:** all CRUD & workflow events captured in `audit_log` with before/after; exportable for audits.
- **Record Protection:** signed certs are read‑only; changes require controlled revision pathways.

---

## 12) Integrations

- **MQTT:** (Phase 2) topics for usage, status, events; optional embedded broker.
- **Web API Server:** REST endpoints (see §14) + Identity Provider (OIDC) for SSO.
- **DB Support:** PostgreSQL primary; MS SQL supported via EF Core provider.

---

## 13) Reporting & Certificates

- Pre‑formatted: Gage Details Sheet, Calibration Certificate, Due Listing, Past‑Due Summary, OOS (Out‑of‑Spec) Incidents, Utilization by Dept, Transfer History, MSA Summaries.
- Ad‑hoc: any list/grid view → column pick → sort/filter → save & export.

---

## 14) API Sketch (REST)

```
GET  /api/gtc/gages?status=past_due&dept=anodize
POST /api/gtc/gages            # create/import
PATCH /api/gtc/gages/{id}
POST /api/gtc/gages/{id}/transfer
POST /api/gtc/gages/{id}/quarantine
POST /api/gtc/calibrations     # create result set
POST /api/gtc/calibrations/{id}/sign  # perform/review/approve
GET  /api/gtc/calibrations/{id}/certificate
POST /api/gtc/schedules/{id}/pause | /resume
POST /api/gtc/notifications/test
POST /api/gtc/msa               # create/run study
GET  /api/gtc/reports/due-list?days=30&dept=*
```

Auth via OIDC bearer; roles/claims enforce module permissions.

---

## 15) Compliance Mapping (evidence pointers)

| Standard | Focus | Evidence in System |
|---|---|---|
| **ISO 9001:2015** | 7.1.5 Monitoring & Measuring Resources | Gage registry, status, calibration records, certificates, traceability, competence |
| **IATF 16949:2016** | Supplemental controls for automotive | Risk‑based schedules, MSA records, traceability, OOS handling |
| **AS9100** | Aerospace QMS | Configuration control, audit logs, approvals, certs |
| **AS13100** | Aero engine specific | Enhanced MSA & process control evidence |
| **ISO 13485:2016** | Medical devices | Calibration records integrity, e‑signatures, change control |
| **ISO/IEC 17025:2017** | Testing/Calibration Labs | Competence, impartiality, method validation, traceability |
| **21 CFR Part 11** | E‑records/e‑signatures | Unique credentials, e‑sig binding, audit trails, record protection |
| **21 CFR 820.72** | Inspection/Measuring Equipment | Calibration program, records, intervals, MSA, labeling |
| **FIPS** | Crypto modules (if applicable) | TLS, hashing, cert management (infrastructure policy) |

> **Note:** This module provides *systemic evidence*; site procedures must still exist.

---

## 16) Archive Manager

- Policies by entity: *archive after N years*; *purge after N+M years* (legal hold aware).
- Archive = moved to cold tables/partitions; searchable via “Include archived”.
- Performance: partition `calibration` by year; compress old partitions.

---

## 17) State Machine & Rules (examples)

**Status gating:**

- *Past Due* blocks issuance to production; user with **OverrideUse** can temporarily release with reason → automatic **Quarantine** after shift end.
- *Quarantined* requires **Approval** to exit; creates CAPA reference (if enabled).

**Frequency adjustment (Phase 2):**

- Keep **pass_streak/fail_streak** counters per gage.
- If `pass_streak ≥ 3` and risk ≤ threshold → increase interval by 10% up to max band.
- If failed, set interval to min band and require review.

**Cost Curve (Phase 2):**

- Model: `total_cost = cal_cost * cal_rate + failure_cost * fail_rate`  
- Sweep intervals to find minimum; store recommendation as advisory on schedule.

---

## 18) UX Notes (Sean‑friendly)

- Saved views (JSON) per user; include columns, sorts, filters, density.
- Split screen: list left, detail right; responsive for laptop 1366×768 and 4K.
- Keyboard power‑user shortcuts (new, clone, transfer, sign).
- Label printing hook (ZPL) from list selection.

---

## 19) Data Quality & Tools

- Dropdown List Manager for controlled vocabularies.
- Bulk **find/replace** with preview & audit.
- **Gage Templates**: pre‑fill fields; *link‑templates* allow batch updates of descendant records (with change log).

---

## 20) Test Plan (high level)

- Unit tests for scheduling math, state machine, NCSL adjust.
- Integration tests for e‑sig flow and certificate immutability.
- API contract tests; role/permission matrix tests.
- Report snapshot tests (golden PDFs).

---

## 21) KPIs & Telemetry

- % On‑time calibrations; mean days past due.
- Failure rate by gage type/vendor.
- Cycle recommendations accepted vs overridden.
- Time‑to‑audit‑pack generation.

---

## 22) Feature Coverage Matrix (from Sean’s list)

- Flexible scheduling w/ pause & reminders → **§6, §10** ✅
- Additional scheduling: activities, crib transfers, MSA → **§6, §8, §9** ✅ (Phase 2 for MSA)
- Configurable interface: split, columns, saved views/filters → **§9, §18** ✅
- Gage templates & data tools; find/replace; dropdowns → **§19** ✅
- Procedure mgmt & linkage → **§4, §5 (procedure_doc)** ✅
- Custom measurement formulas → **§7** (Phase 2) ✅
- Auto frequency adjust & cost curve → **§6, §17** (Phase 2) ✅
- Group‑level security → **§3** ✅
- Archive manager → **§16** ✅
- Industry reports & certs → **§13** ✅
- Ad‑hoc reporting → **§13** ✅
- Due dashboard & calendar DnD → **§9** (calendar Phase 2) ✅
- Enhanced due (activities, crib, MSA) → **§9** (Phase 2 MSA) ✅
- Custodian management → **§3, §5** ✅
- Helpful data entry tools (cloning, FR) → **§19** ✅
- Crib & service request mgmt → **§9 Transfers** + **Phase 2 workflows** ✅
- Electronic calibration signatures → **§11** ✅
- Complete life cycle tracking + Where Used/History → **§4, §9** ✅
- MSA (R&R, Linearity, Stability) → **§8** (Phase 2) ✅
- Notification manager & event notifications → **§10** ✅
- Latest .NET / Uno stack → **Top**, **§9** ✅
- MS SQL + PostgreSQL → **§12** ✅
- MQTT Publisher/Broker → **§12** (Phase 2) ✅
- Web API + Identity Provider → **§12, §14** (optional) ✅
- SMTP/Graph API → **§10** ✅
- Compliance (ISO/IATF/AS/17025/21CFR/FIPS) → **§15** ✅

---

## 23) Roadmap & Estimates (t‑shirt)

- **Phase 1 (MVP, 8–12 wks):** registry, schedules, procedures, certs, e‑sig, reports, transfers, notifications, archive, security, dashboards (no MSA).
- **Phase 2 (6–10 wks):** MSA, formula mgr, auto‑frequency + cost curve, calendar DnD, MQTT/API, enhanced workflows.

> Dependencies: Identity (OIDC) selection, PDF renderer (QuestPDF), charting (LiveCharts/Uno), email (Graph), EF Core providers.

---

## 24) Open Questions

1. Will usage‑based scheduling integrate with Shop floor data (existing signals)?
2. Do we need on‑prem only mode for ITAR/FIPS (no cloud dependencies)?
3. Certificate template branding—per site or per company?
4. Auditor portal (read‑only external) out of scope or Phase 3?

---

**End of v0.1** — Ready for review & iteration.
