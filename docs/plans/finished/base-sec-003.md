# BASE-SEC-003 plan: authorize every SELECT source

_Date: 2026-08-06 · branch: `codex/fix-base-sec-003`_

## Goal

Close the nested-source authorization bypass by identifying and checking every physical `FROM`/`JOIN` source in each SELECT branch before generated ABAP is created.

## Patch contract

- Vulnerable path: editor input → `QUERY_PARSE` top-level `FW_FROM` split → incomplete `ZTOAD_AUTH` check → `QUERY_GENERATE` → generated ABAP SQL.
- Attacker prerequisite: ZTOAD access plus authorization for an outer table but not a concealed inner source, or an equivalent restricted fallback pattern.
- Invariant: no physical SELECT source reaches generation without the current activity-03/table policy; unprovable dynamic/CTE/comment/path/hierarchy sources fail closed, including attached path tokens.
- Preserved behavior: authorized simple sources, aliases, ordinary joins, nested subqueries, `UNION`/`UNION ALL` source checking, real `HIERARCHY_*` table names, parser output, row limits, and SAP_BASIS 750 syntax.
- Out of scope: full validation/escaping of column and condition tokens (`BASE-SEC-001`), support for parenthesized join expressions, and a complete SQL grammar redesign.

## Reviewed sequence

1. Revalidate the source-to-generation path and SAP security/subquery guidance; document the boundary and rejected alternatives.
2. Add focused ABAP Unit tests for unauthorized/authorized nested sources, two-level nesting, joins, quoted keywords, comments, dynamic sources, and unsupported CTE input. Activate the test-only source on A4H and record the intended red failure without executing SQL.
3. Review the plan for authorization completeness, false positives, 7.50 syntax, Clean ABAP/Clean Core, error semantics, and interaction with the open SEC-002 PR.
4. Add a pure local scanner that walks the current branch once, tracks quoted-literal state, collects physical sources after `FROM`/`JOIN`, deduplicates them, and flags unprovable dynamic/CTE/comment syntax.
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
- Dynamic/host/CTE/path/hierarchy sources are rejected rather than guessed. The path test covers both a leading backslash and the SAP-documented attached form; accepting either without resolving the association targets would violate the patch invariant.
- The scanner sees the complete input branch, so it also checks sources after `UNION ALL` even though the legacy parser does not split that spelling. Parenthesized joins deliberately fail closed until their grammar is modeled.
- The scanner is a cohesive pure local class, a small step away from the large FORM routine without broad refactoring.
- SEC-003 remains based on `master`; it does not depend on or duplicate SEC-002. Integrate the P0 PRs as #18, then #20, then this PR #19; rebase and repeat affected local/A4H evidence after each predecessor rather than resolving the overlapping report text mechanically.

## Evidence log

- Baseline restore: A4H was explicitly returned to `master`; 19/19 ABAP Unit tests pass and the known four syntax warnings are present.
- SAP Docs MCP: dynamic external table sources require include-list checks; generated programs are the least safe dynamic technique; nested subqueries have independent FROM sources.
- ABAP Unit red: the test-only source activated on A4H with the known four warnings. Of 26 tests, 22 passed and exactly four focused assertions failed: `REJECTS_UNAUTHORIZED_SUBQUERY`, `REJECTS_TWO_LEVEL_SUBQUERY`, `REJECTS_DYNAMIC_SOURCE`, and `REJECTS_UNSUPPORTED_CTE`. Authorized subquery/join and literal/comment-keyword controls passed. Coverage was 15.72% statements, 14.07% branches, and 6.58% procedures.
- Implementation: `LCL_SQL_SOURCE_SCANNER` walks each current SELECT branch once, ignores quoted text, deduplicates physical `FROM`/`JOIN` sources, rejects unsupported dynamic/host/CTE/comment/path/hierarchy sources, and passes the result through the unchanged authorization object or fallback-pattern policy. Later-UNION-branch, generated-line comment, path-expression, and hierarchy regressions were added during implementation/final security review.
- ABAP Unit green: the final grammar-hardened candidate passed 30/30 on A4H. Coverage is 18.69% statements, 18.57% branches, and 8.97% procedures. Earlier 27- and 28-test candidates were also fully green.
- Local final checks: `npm ci`, `npm test`, `npm run lint:quality`, and `git diff --check` passed. Configured abaplint remains at zero. After the external-review regressions, the diagnostic full-quality inventory is 1,959 findings across 58 legacy rules and is not yet a merge gate.
- A4H pre-review candidate: source SHA-256 `2e01300cd07d2ee4a9f07965c1f719a71bc5b572b8c52cd4210d572b08907e5f` passed server preflight, activation, active syntax, and active/inactive source comparison. Syntax had zero errors and the four known warnings. A fresh FLP/WebGUI launch reached the ZTOAD editor without SQL execution; no ST22 entry appeared after the pre-existing 2026-08-06 09:30:59Z dump. The 49-object inactive inventory still contained the seven known ZTOAD main/child records tracked by `BASE-BUG-007`.
- ATC: final `ABAP_CLOUD_READINESS` returned 769 findings (464 P1, 305 P2), a one-P1 run-to-run difference from the recorded master result; no finding points into the production scanner. The test helper retains the already accepted restricted-`FORM` warning class used by the characterization suite. `S4HANA_READINESS_2023` returned zero rows but remains non-authoritative because its seven known prerequisite checks are unavailable.
- NPL ADT-only: ARC-1 1.0.2 reached the SAP_BASIS 750 system as `DEVELOPER`; both `PROG ZTOAD` and `TABL ZTOAD` remain absent. Exact activation/syntax/Unit validation is therefore prerequisite-blocked and no GUI fallback was used.
- First PR CI: GitHub Actions run `31104885408` passed `Repository quality (ABAP 7.50)`; the abaplint app passed and its observation job was intentionally skipped.
- Post-green audit: the red/green/live/final-review sequence caught the generated-source comment boundary before publication. The durable improvement is an explicit representation-boundary review in `AGENTS.md`, this playbook, and the PR template; long-lived docs no longer hard-code a test count that becomes stale. The Quality workflow itself is correctly scoped, pinned, cached, and green, so no CI code change was justified.
- Post-audit CI: GitHub Actions run `31105030456` passed on head `c14ba791bfc015d58f1ff5953460debd05f06378`. The subsequent full-grammar review added fail-closed path-expression and hierarchy cases. GitHub Actions run `31105406732` then passed on implementation/evidence head `8bba88d`; this final evidence-only commit requires the last green head check before readiness.
- External review replay: SAP Docs MCP confirmed that a data-source path expression attaches directly to its exposed unit. A test-only A4H replay passed 32/34 tests and failed exactly `REJECTS_ATTACHED_PATH_SOURCE` and `ACCEPTS_HIERARCHY_NAMED_TABLE` against the previous implementation. Rejecting `\` anywhere in the source token and matching only the exact `HIERARCHY` constructor turned the same suite green at 34/34. The exact final source SHA-256 `88bbed3e82eeff672bbbdf74eaa710a8749de391362fc5f7870843971b6d38c9` activated with zero syntax errors and four known warnings; active/inactive source matched at server-normalized SHA-256 `ecb1d3c5495716c30305ab3c4a96b83082d69c89d151e9035464e2ea7c2c7fec`. Coverage remained 18.69% statements, 18.57% branches, and 8.97% procedures. `ABAP_CLOUD_READINESS` returned 769 findings (464 P1, 305 P2), and `S4HANA_READINESS_2023` returned no rows but remains incomplete. The added parenthesized-join test records the intentional compatibility limitation; the `UNION ALL` test confirms its later unauthorized source was already seen by the full-input scanner.

## Post-PR #18/#20 integration validation

- The branch was rebased after PR #18 removed Native SQL and PR #20 hardened both generated-program sinks. Conflicts were resolved semantically and the complete predecessor production/test corpus was retained.
- The exact integrated source SHA-256 `339a53f579fcde6b95dee08841a421fbe510839d06113902c800b6c28eee5397` passed repository tests, configured abaplint with zero findings, A4H server preflight, activation, syntax, ABAP Unit, active/inactive comparison, ATC, and the safe browser smoke. The server-normalized source SHA-256 was `46789b7a44ac06953e9a69a03f19199d6192ebf10327aa24c3e13c77d1e9c654`.
- A4H syntax reported zero errors and two pre-existing POSIX warnings. All 55 ABAP Unit tests passed. Coverage was 25.07% statements, 24.10% branches, and 16.87% procedures.
- `ABAP_CLOUD_READINESS` returned 668 findings (462 P1, 206 P2). `S4HANA_READINESS_2023` returned no rows but remains incomplete because its prerequisite checks are unavailable. The diagnostic full abaplint profile reported 2,030 findings across 59 rules and remains non-blocking; configured abaplint remains the zero-findings merge gate.
- A fresh A4H FLP/WebGUI startup rendered the editor and DDIC pane with no browser error. No SQL was executed and the before/after ST22 identifiers were identical. Missing GUI status `STATUS010` remains the independent `BASE-BUG-007` installation finding.
