# BASE-SEC-003 plan: authorize every SELECT source

_Date: 2026-08-06 · branch: `codex/fix-base-sec-003`_

## Goal

Close the nested-source authorization bypass by identifying and checking every physical `FROM`/`JOIN` source in each SELECT branch before generated ABAP is created.

## Patch contract

- Vulnerable path: editor input → `QUERY_PARSE` top-level `FW_FROM` split → incomplete `ZTOAD_AUTH` check → `QUERY_GENERATE` → generated ABAP SQL.
- Attacker prerequisite: ZTOAD access plus authorization for an outer table but not a concealed inner source, or an equivalent restricted fallback pattern.
- Invariant: no physical SELECT source reaches generation without the current activity-03/table policy; unprovable dynamic/CTE/comment sources fail closed.
- Preserved behavior: authorized simple sources, aliases, joins, nested subqueries, UNION branch processing, parser output, row limits, and SAP_BASIS 750 syntax.
- Out of scope: full validation/escaping of column and condition tokens (`BASE-SEC-001`) and a complete SQL grammar redesign.

## Reviewed sequence

1. Revalidate the source-to-generation path and SAP security/subquery guidance; document the boundary and rejected alternatives.
2. Add focused ABAP Unit tests for unauthorized/authorized nested sources, two-level nesting, joins, quoted keywords, comments, dynamic sources, and unsupported CTE input. Activate the test-only source on A4H and record the intended red failure without executing SQL.
3. Review the plan for authorization completeness, false positives, 7.50 syntax, Clean ABAP/Clean Core, error semantics, and interaction with the open SEC-002 PR.
4. Add a pure local scanner that walks the current branch once, tracks quote/comment state, collects physical sources after `FROM`/`JOIN`, deduplicates them, and flags unprovable source syntax.
5. Replace the top-level space-split authorization loop with scanner output while retaining the existing authorization object/fallback semantics and error message.
6. Run `npm ci`, `npm test`, `npm run lint:quality`, `git diff --check`, focused bypass review, and the full diff/security review. Confirm the live red source becomes green only after the production change.
7. Deploy the exact candidate to A4H through ARC-1 with server preflight and explicit activation; verify active/inactive main source, inactive child parts, active syntax, all ABAP Unit tests with coverage, and both recorded ATC variants.
8. Run a fresh A4H transaction-start smoke with no SQL execution and verify the ST22 delta. Keep missing `STATUS010` classified as `BASE-BUG-007`.
9. Probe NPL only through the configured ARC-1/ADT profile and record the existing missing PROG/TABL prerequisite without GUI fallback.
10. Complete final implementation/security/release review, update the finding register, open a draft PR, and wait for first green CI.
11. Audit workflow and CI after first green, apply clearly useful process improvements, move this plan to `docs/plans/finished/`, push, and wait for final green CI.

## Plan review

- Scanning the complete current branch closes nested-subquery concealment without prohibiting supported subqueries.
- Quote awareness prevents false table checks on literal data. Comments fail closed because the generator's 255-character source wrapping makes their effective end position unsafe to predict at this boundary.
- Dynamic/host/CTE sources are rejected rather than guessed. Accepting a source whose physical object cannot be proven would violate the patch invariant.
- UNION is already processed branch by branch by `QUERY_PROCESS`; tests cover scanner input and existing branch separation so no second execution path is introduced.
- The scanner is a cohesive pure local class, a small step away from the large FORM routine without broad refactoring.
- SEC-003 remains based on `master`; it does not depend on or duplicate SEC-002. The PRs may both touch nearby tests/docs and will require the recommended merge order/rebase review.

## Evidence log

- Baseline restore: A4H was explicitly returned to `master`; 19/19 ABAP Unit tests pass and the known four syntax warnings are present.
- SAP Docs MCP: dynamic external table sources require include-list checks; generated programs are the least safe dynamic technique; nested subqueries have independent FROM sources.
- ABAP Unit red: the test-only source activated on A4H with the known four warnings. Of 26 tests, 22 passed and exactly four focused assertions failed: `REJECTS_UNAUTHORIZED_SUBQUERY`, `REJECTS_TWO_LEVEL_SUBQUERY`, `REJECTS_DYNAMIC_SOURCE`, and `REJECTS_UNSUPPORTED_CTE`. Authorized subquery/join and literal/comment-keyword controls passed. Coverage was 15.72% statements, 14.07% branches, and 6.58% procedures.
- Implementation: `LCL_SQL_SOURCE_SCANNER` walks each current SELECT branch once, ignores quoted text, deduplicates physical `FROM`/`JOIN` sources, rejects unsupported dynamic/host/CTE/comment sources, and passes the result through the unchanged authorization object or fallback-pattern policy. Later-UNION-branch and generated-line comment regressions were added during implementation/final security review.
- ABAP Unit green: the final comment-hardened candidate passed 28/28 on A4H. Coverage is 18.54% statements, 18.34% branches, and 8.97% procedures. The earlier 27-test candidate was also fully green.
- Local final checks: `npm ci`, `npm test`, `npm run lint:quality`, and `git diff --check` passed. Configured abaplint remains at zero. The final diagnostic full-quality inventory is 1,945 findings across 58 legacy rules and is not yet a merge gate.
- A4H: final exact source SHA-256 `2d1589fd902a2decd762c1748bc893e60c4de6b74cd2d195d1aacddf0f0a9326` passed server preflight, activation, active syntax, and active/inactive source comparison. Syntax has zero errors and the four known warnings. A fresh FLP/WebGUI launch reached the ZTOAD editor without SQL execution; no ST22 entry appeared after the pre-existing 2026-08-06 09:30:59Z dump. The 49-object inactive inventory still contains the seven known ZTOAD main/child records tracked by `BASE-BUG-007`.
- ATC: final `ABAP_CLOUD_READINESS` returned 769 findings (464 P1, 305 P2), a one-P1 run-to-run difference from the recorded master result; no finding points into the production scanner. The test helper retains the already accepted restricted-`FORM` warning class used by the characterization suite. `S4HANA_READINESS_2023` returned zero rows but remains non-authoritative because its seven known prerequisite checks are unavailable.
- NPL ADT-only: ARC-1 1.0.2 reached the SAP_BASIS 750 system as `DEVELOPER`; both `PROG ZTOAD` and `TABL ZTOAD` remain absent. Exact activation/syntax/Unit validation is therefore prerequisite-blocked and no GUI fallback was used.
- First PR CI: pending.
- Post-green audit/final CI: pending.
