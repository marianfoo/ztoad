# BASE-SEC-002 plan: retire arbitrary Native SQL

_Date: 2026-08-06 · branch: `codex/fix-base-sec-002`_

## Goal

Remove the externally controlled Native SQL execution boundary and unsupported `C_DB_EXECUTE` call while preserving existing ABAP SQL SELECT, INSERT, UPDATE, and DELETE behavior.

## Patch contract

- Vulnerable source-to-sink: editor input → `QUERY_PARSE_NOSELECT` → `QUERY_PROCESS_NATIVE` → `C_DB_EXECUTE`.
- Attacker prerequisite: access to ZTOAD plus activity `16` in `ZTOAD_AUTH`, or a system with fallback `auth_native` enabled.
- Invariant: `NATIVE` always fails closed and no user-supplied statement reaches a Native SQL API/kernel call.
- Preserved behavior: normal query parsing/generation, UPDATE and DELETE parsing, GUI startup, authorization for supported ABAP SQL commands, SAP_BASIS 750 syntax.
- Intentional compatibility change: the legacy `NATIVE` feature cannot be enabled after this patch.

## Reviewed sequence

1. Revalidate the live source-to-sink path and SAP guidance; document why an ADBC API swap or regex allow list would not close the injection boundary.
2. Add an architectural repository contract that fails while `C_DB_EXECUTE` exists; run `npm test` and record the focused red failure.
3. Review the plan for security closure, legitimate behavior, 7.50 compatibility, Clean ABAP/Clean Core, error semantics, rollback, and live-test safety.
4. Add ABAP Unit tests proving default rejection and rejection despite the legacy enable flag. Preserve positive UPDATE/DELETE parser tests.
5. Make the smallest production change: reject `NATIVE` unconditionally, remove its dispatch branch, and delete `QUERY_PROCESS_NATIVE`/`C_DB_EXECUTE`.
6. Review touched code against Clean ABAP without mass-refactoring the legacy report. Run `npm ci`, `npm test`, `npm run lint:quality`, `git diff --check`, security bypass review, and verify that reverting the production change makes the focused tests red.
7. Deploy the exact candidate to A4H with ARC-1, activate explicitly, compare active/inactive main source, review inactive child parts, run active syntax, all ABAP Unit tests, and ATC variants.
8. Run a fresh A4H transaction-start smoke and pre/post ST22 delta without executing SQL. Keep missing `STATUS010` classified as `BASE-BUG-007`.
9. Probe NPL only through ARC-1/ADT and record the existing missing-object prerequisite honestly.
10. Complete final diff/security/release review, update the findings register and documentation, open a draft PR, and wait for the first green CI cycle.
11. Audit the workflow and CI output after first green, apply clearly beneficial process improvements in the same PR, move this plan to `docs/plans/finished/`, and wait for final green CI.

## Plan review

- Removing the feature is narrower and more secure than building a new database-administration subsystem inside this bug fix.
- Parser tests exercise the real command boundary and the repository contract permanently prevents the unsupported sink from returning.
- No destructive proof is necessary or allowed: rejection before execution is the behavior under test.
- The existing confirmation popup is deleted with the executor because user confirmation cannot authorize otherwise unsafe SQL text.
- The legacy customization fields can remain temporarily for persisted-layout compatibility, but they must no longer affect control flow; their later removal is non-security cleanup.
- No serializer XML or structural object changes belong in this source-only PR.

## Evidence log

- Baseline: `npm ci` reports 0 vulnerabilities; `npm test` passes with 0 configured abaplint issues; full diagnostic lint reports 1,878 findings across 58 rules.
- Red repository contract: `npm test` reached the new focused assertion and failed because `src/ztoad.prog.abap` still contains `C_DB_EXECUTE` (`AssertionError: Unsupported native SQL kernel call C_DB_EXECUTE must not exist`). Configured abaplint remained green with 0 findings before the contract ran.
- ABAP Unit red: the test-only candidate activated on A4H with the four known warnings. Of 20 tests, 19 passed and only `LTC_COMMAND_PARSER=>CANNOT_REENABLE_NATIVE_SQL` failed (`ASSERT_INITIAL`) because setting the deprecated fallback flag still copied Native SQL into the executable parameter. `REJECTS_NATIVE_SQL_BY_DEFAULT`, UPDATE, and DELETE remained green. Coverage was 15.40% statements, 13.32% branches, and 6.58% procedures.
- ABAP Unit green: the implemented candidate passed all 20 tests on A4H. Coverage was 15.31% statements, 12.90% branches, and 6.67% procedures; the lower totals reflect deletion of the executor form.
- Local final checks: `npm ci` found 0 vulnerabilities; configured abaplint and the repository contract passed; `git diff --check` passed. The full diagnostic inventory fell from 1,878 to 1,841 findings across the same 58 rules. Source searches found no executor form, dispatch, or `C_DB_EXECUTE`; only historical/research references remain.
- A4H: the exact local report source was written through ARC-1 with only its mis-profiled pre-write lint disabled, server preflight retained, and explicit activation. Active syntax has 0 errors and only the 3 known POSIX warnings. Active/inactive main source has no difference. The 7 known inactive child parts remain attributable to `BASE-BUG-007`. `ABAP_CLOUD_READINESS` fell from 768 (463 P1/305 P2) to 759 (457 P1/302 P2). `S4HANA_READINESS_2023` again returned 0 rows but remains non-authoritative because 7 prerequisite checks are unavailable. A fresh FLP/WebGUI transaction start rendered the editor, reproduced only missing `STATUS010`, executed no SQL, and created no ST22 dump after the 09:30:59Z marker.
- NPL ADT-only: the configured ARC-1 1.0.2 profile reached SAP_BASIS 750, but both `PROG ZTOAD` and required `TABL ZTOAD` are absent. Exact activation/syntax/Unit/ATC therefore remains prerequisite-blocked; no GUI fallback or substitute object was used.
- First PR CI: pending.
- Post-green audit/final CI: pending.
