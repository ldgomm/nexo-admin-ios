# Nexo 28R.M — Admin iOS finance-control UX

Status: implemented pending evidence review.

## Scope

The Admin iOS surface provides permission-aware oversight for:

1. organisation, legal entity and ledger policy;
2. chart, category and cost-centre configuration;
3. period status and locks;
4. historical import batches and row errors;
5. replay, backfill and coverage;
6. reconciliation exceptions;
7. cutover approval;
8. jurisdiction-pack capabilities;
9. audit and evidence drill-down;
10. compliance statements limited to verified capabilities.

## Safety boundary

- The backend is the source of truth.
- The app does not calculate authoritative financial totals.
- The phase remains `OPERATIONAL_NOT_POSTED`.
- No general-ledger posting is performed.
- Runtime repositories fail closed until 28R.P.
- A cutover approval requires explicit permission, backend capability, zero
  blocking items, zero overlaps/gaps, evidence and a non-empty reason.
- A jurisdiction statement is rejected when any claimed capability is not
  verified or when verification evidence is missing.
- External references included in evidence must remain masked.

## Deferred work

- Runtime endpoint wiring and live smoke: 28R.P.
- Ecuador migration and portability proof: 28R.N.
- Security, concurrency and final RBAC hardening: 28R.O.
- Canonical accounting posting: 29R.

## Exit gate

28R.M passes only when the Admin app builds, the focused finance-control tests
pass, the full Admin test suite passes, target identities remain stable, the
evidence manifest is complete and the secret scan is clean.
