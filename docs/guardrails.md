# Responsible AI & Guardrails (spec station 9)

**One-paragraph statement (spec §4):** Commencys collects only what
coordination needs; precision GPS is visible solely to authorised
coordinators and the assigned verified volunteer. The UI always distinguishes
*report acknowledged* from *volunteer dispatched* so no reporter mistakes a
stored ticket for incoming help. IndoBERT labels and DBSCAN clusters are
advisory metadata — low-confidence outputs are flagged for human review and
no merge is irreversible. Every decision and inference lands in an immutable
audit log under access and retention controls. Commencys is a community
early-response aid, **not** a substitute for official emergency services
(112 / SPGDT 119).

## Controls

1. **Data minimisation:** SOS payload = location + accuracy + short text +
   optional photo. No background tracking; location is event-scoped.
2. **Access scoping:** precision coordinates → coordinator role + assigned
   volunteer only (row-level policy on `incidents.geom`); public feeds carry
   coarse/approximate location. (`db-schema.md`)
3. **Status honesty:** `acknowledged ≠ dispatched` enforced in schema, API,
   and UI stepper (criterion 3; `02-design.md`).
4. **Human review:** confidence `< 0.65` → `needs_review`; coordinator can
   correct labels and split clusters; corrections are audit-logged.
5. **Immutable audit:** `audit_log` is append-only (`REVOKE UPDATE, DELETE`);
   AI writes include model version + confidence.
6. **No autonomous action:** no LLM executes handling decisions; any future
   assistant is read-only + drafts (station 6).
7. **No medical overreach:** system never issues standalone medical guidance;
   future LLM summarisation is advisory-only with officer verification.
8. **Not-112/119 positioning:** in-app disclaimer on the SOS screen and in
   onboarding — "alat bantu respons dini komunitas, bukan pengganti 112/119".
9. **Retention:** raw reports + audit per campus policy; photo evidence
  iseb footprint-minimal with expiry; export/deletion procedure in
   `06-maintenance.md`.
