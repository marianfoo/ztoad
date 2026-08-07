# BASE-BUG-002 plan: generate aggregate CASE result types

## Goal

Make the `SUM( CASE ... END ) AS ...` form reported in GitHub issue #7 produce a valid generated subroutine pool while preserving existing aggregate behavior, authorization, injection controls, ABAP 7.50 compatibility, and ALV field metadata.

## Scope

- In scope: simple and searched CASE inside `SUM`, a direct qualified or unqualified DDIC column at the start of a result branch, alias metadata, focused parser/generator characterization, and exact A4H validation.
- Out of scope: arbitrary SQL-expression type inference, nested built-in-function support, generic select-list tokenization, executing the reported business query, provisioning ZTOAD on NPL, or resolving other open function/parser issues. A read-only SFLIGHT query using the sanitized regression grammar is in scope for the A4H smoke test.

## TDD and implementation sequence

1. Replay the test-only red candidate on the final integrated base: the added `GENERATES_CASE_SUM_EXPRESSION` test must be the only failure, and no SQL may execute. The earlier 55/56 result is historical evidence, not a substitute for this rerun.
2. Add a small pure select-expression analyzer with tests for simple CASE, searched CASE, qualified/unqualified results, quoted `THEN` lookalikes (including spaces and doubled quotes), and an unprovable literal result.
3. During existing aggregate-token collection, ask the analyzer for the first provable CASE result-column reference. Keep the original SELECT text unchanged.
4. Feed the proven reference through the existing table-alias/DDIC type path. For CASE aggregates, keep the SQL alias as display metadata instead of claiming that the computed value is the physical source field.
5. Extend the generator helper/test to assert a generated pool, strict/new syntax, table-result mode, and alias-preserving field metadata. Add a searched-CASE generator regression and retain all earlier aggregate/security tests.
6. Run configured abaplint, repository-contract checks, the full diagnostic lint inventory, and `git diff --check`. Review touched code against Clean ABAP without mass-refactoring the legacy report.
7. Deploy the exact source to A4H through ARC-1 with server preflight and explicit activation. Run active syntax, all ABAP Unit tests with coverage, object-state comparison, both recorded ATC variants, and a fresh WebGUI execution of the sanitized read-only CASE query plus ST22 delta.
8. Reconfirm the 7.50 limitation through ARC-1/ADT only. If ZTOAD remains absent on NPL, record the existing prerequisite blocker rather than claiming a live pass.
9. Review the implementation, security boundaries, test names, documentation placement, and development process; update the existing PR #21 only after PR #24 is merged and this branch is rebased onto the resulting `master`.
10. Wait for the first required green GitHub run, audit the process/CI, apply useful guidance changes in the same PR, move this plan to `docs/plans/finished/`, and wait for CI again.

## Review criteria

- The analyzer returns only a restricted DDIC column token and never rewrites executable SQL.
- A quoted keyword or non-column result cannot be mistaken for a type reference. Literal masking must preserve token boundaries, handle doubled SQL quotes, and fail closed on an unbalanced literal.
- Unsupported CASE result forms fail through the existing no-program contract.
- Generated-program syntax remains the final proof that the chosen result target is compatible with the complete CASE expression.
- Existing direct fields, `COUNT`, `AVG`, simple `SUM`/`MAX`/`MIN`, top-level CASE, strict clause ordering, authorization, input validation, and line-boundary tests stay green.
- The patch introduces no post-7.50 production syntax and does not weaken configured abaplint.

## Integration status

- The original PR #21 implementation was based on `612330c`, before the P0 security fixes, complete-object installation repair, and WebGUI capability adapter. Its old commit hashes, test totals, ATC totals, browser limitation, and live source hashes are stale.
- PR #24 was squash-merged as `5218476`; the integration series was rebased deliberately onto that exact tree. Configured abaplint, repository/install contracts, `npm ci`, `git diff --check`, and the diagnostic 2,169-finding/63-rule inventory are complete.
- Detailed review added two adversarial regressions. The inherited space-split analyzer would stop at `THEN` inside `'X THEN Y'` or `'X'' THEN Y'`; a quote-aware literal masker now removes literal contents before token analysis and handles doubled quotes without rewriting executable SQL.
- The rebased test-only candidate reproduced 57/58: only `GENERATES_CASE_SUM_EXPRESSION` failed. The first green candidate exposed an ABAP representation bug live: `&&` trimmed a one-character `TYPE c` blank, removed every token boundary, and caused eight CASE-dependent failures (59/67). Replacing those concatenations with `CONCATENATE ... RESPECTING BLANKS` made the existing tests exercise the intended representation.
- Exact source commit `36579848804e822f0863827479e221e3000231b5` has local SHA-256 `8ac6f8ddc965c08d53f87995403c8271d4d95542d73d567387a222389a65283e`. A4H activation and active syntax passed with zero errors/two existing POSIX warnings; all 67 Unit tests passed with 26.98% statement, 26.31% branch, and 20.45% procedure coverage. Active/inactive source matched at server SHA-256 `e32d7d3b8bebdb38457cd81f52e90a3b00dc0e830ac537b7690b70cee4544897`, with no inactive ZTOAD child part.
- Complete `ABAP_CLOUD_READINESS` remained 682 findings (474 P1/208 P2), so the patch added no released-API finding. `S4HANA_READINESS_2023` returned zero rows but remains prerequisite-incomplete. NPL 7.50 again returned no PROG/TABL object for ZTOAD, so the exact gate remains blocked rather than passed.
- A fresh marked WebGUI session executed the sanitized SFLIGHT CASE aggregate, returned eight grouped rows with `NET_PRICE` metadata, and exited cleanly with F3. Client-side comparison found no ST22 dump newer than the `2026-08-07T06:26:10Z` marker. A4H was then restored and explicitly activated to exact master `5218476`; 57/57 master tests, syntax/state, inactive-child inventory, and native-abapGit check are green at server SHA-256 `138d7cf38e68649abb7d714093afc809a27f7a26ca98b511d15dec4ef68d9e36`.
