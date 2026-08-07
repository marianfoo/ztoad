# BASE-BUG-005 implementation plan

Status: implementation and exact live validation complete; pull request pending.

## Goal

Execute top-level `UNION`, `UNION DISTINCT`, and `UNION ALL` as one ABAP SQL set
expression with SAP-owned duplicate and layout semantics, while preserving the
ZTOAD row cap, authorization policy, SAP_BASIS 750 compatibility, and literal/
subquery boundaries.

## Scope and invariants

- Preserve the operator and optional modifier with the right branch.
- Accept supported SQL whitespace around the operator and ignore operator-like
  text inside literals or nested parentheses.
- Authorize every physical source in the complete query before generation.
- Run one generated program and one database cursor for the complete set.
- Let SAP syntax reject incompatible branch counts or types; never append
  generic branch tables in ABAP.
- Treat only a final `UP TO n ROWS` as ZTOAD's merged-result cap. Reject a row
  restriction that is followed by another top-level set branch.
- Use `FETCH ... PACKAGE SIZE` for nonzero limits and one unbounded `FETCH` only
  for the existing explicit `UP TO 0 ROWS` contract.
- Do not add `INTERSECT`, `EXCEPT`, CTE, path, hierarchy, dynamic-source, DML,
  or Native SQL support in this change.

## Implementation

1. Move row-cap and caller-target removal ahead of set splitting so they apply
   to the complete input representation.
2. Extend the top-level set pattern to `UNION [ALL|DISTINCT] SELECT`, preserve
   the suffix from the `UNION` token, and force strict host-variable syntax.
3. Reject a matched row cap if another top-level `UNION` follows it.
4. In `QUERY_PROCESS`, attach the preserved suffix to the first query tail and
   clear the legacy branch loop input before generation.
5. Detect a real top-level set operator again at the generator sink. Generate
   `OPEN CURSOR` over the complete validated SQL, fetch the configured package
   into the inferred result table, capture the row count, and close the cursor.
6. Force aggregate set queries through the tabular path rather than the
   legacy `SELECT SINGLE` shortcut.
7. Preserve the DDIC tree's multi-source view by deriving its source list from
   the already-used quote-aware scanner instead of reparsing branch fragments.
8. Remove only branch-loop code that is proven unreachable after the new
   single-set path; avoid unrelated report refactoring.

## Test matrix

- Red tests already recorded: operator preservation, whitespace/multiline
  `UNION ALL`, per-branch limit rejection, implicit-distinct execution,
  duplicate-preserving `ALL`, mismatched layouts, and merged-result limit.
- Add/retain coverage for explicit `UNION DISTINCT`, three branches, final
  `UP TO 0`, literal/nested `UNION` lookalikes, unauthorized later sources,
  source comments, and safe generated-line splitting.
- Confirm all 97+ ABAP Unit tests, including invalid/untrusted input cases.
- Local gates: `npm ci`, `npm test`, `git diff --check`, full diff review,
  abaplint and repository/installation contracts.

## Live validation

Freeze the candidate in a commit and record its local source hash. On
SAP_BASIS 750 first, then S/4HANA 2023:

1. write the exact candidate, explicitly activate it, and require active/
   inactive main-source equality;
2. require active syntax, the complete ABAP Unit suite, resolved ATC variants,
   complete ATC results or explicit prerequisite failures, and no inactive
   ZTOAD child parts;
3. on A4H only, snapshot ST22, open a fresh WebGUI session, enter a harmless
   aggregate `UNION ALL` query with real editor/change/blur actions, execute it,
   verify the one-row capped result, then compare the complete returned dump
   set client-side;
4. restore both shared systems to intended `master` and reverify activation,
   hash equality, Unit, and inactive-object state.

The real SAP endpoint and credentials remain only in ignored local
configuration and must not appear in evidence, commits, logs, or PR text.

## Clean ABAP, Clean Core, and rollback review

The change keeps the legacy FORM boundary small and places grammar decisions in
the existing pure scanners. It uses released ABAP SQL/cursor statements that
compile on the 7.50 floor and introduces no SAP-internal API dependency. Cursor
closure is explicit. Tests are harmless, short, read-only, and use stable DDIC
tables only for aggregate results.

Rollback is the single production commit plus test/docs commits. If a live gate
fails, restore the exact current `master` source on both systems, activate, and
verify its recorded server-normalized hash before continuing.

## Plan review

Reviewed against the red failures, SAP Docs MCP references, both live compiler
probes, the security boundary, result-size policy, and the repository workflow.
The cursor design is preferred because it delegates set semantics and branch
compatibility to SAP while retaining a bounded fetch. The main implementation
risk is generated target compatibility; the mismatch and runtime row-count
tests exercise that boundary directly on both compilers.

## Completed candidate evidence

- Frozen candidate: `58aed8d443d3837bdc94b579e0b4f6b5bfba96df`.
- Local source SHA-256:
  `9848ace8fadb61ef72a0a28a7ee011e72d8e58ebebad4514d3268eafcb940a2e`.
- Server-normalized source SHA-256 on both targets:
  `7ab32de5518a77c996e6dc1341618df4480c928ebd6529c63a918ab199e54d63`.
- Local: `npm ci`, `npm test`, and `git diff --check` passed; configured
  abaplint has zero findings and all repository/installation contracts passed.
- NPL/SAP_BASIS 750: explicit activation, zero syntax errors or warnings,
  106/106 Unit, equal active/inactive source, no inactive ZTOAD part, and a
  complete DEFAULT ATC run with 86 findings (3 P1, 4 P2, 79 P3).
- A4H/SAP_BASIS 758: explicit activation, zero syntax errors, the seven known
  POSIX-regex deprecation warnings, 106/106 Unit, equal active/inactive source,
  and no inactive ZTOAD part.
- A4H `ABAP_CLOUD_READINESS`: complete run with 697 findings (487 P1,
  210 P2). The increase from 682 is in executable report-local test code and is
  retained as architectural debt under `BASE-ARCH-003`; it does not establish
  a Clean Core claim. `S4HANA_READINESS_2023` returned zero rows but remains
  prerequisite-incomplete.
- Fresh A4H WebGUI smoke: a real user-typed, read-only `UNION ALL` aggregate
  with a final one-row cap executed successfully and returned exactly one ALV
  row. Comparing the complete 50-entry ST22 sets before and after found no new
  dump.
- After evidence collection, both shared systems were restored and explicitly
  activated to released master `15e6258`: 91/91 Unit, equal active/inactive
  server SHA-256 `fa0332e5679236d636bece64cbb3e28b3dccf2e8b21112c69efadd550ea78d0b`,
  and no inactive ZTOAD part.
