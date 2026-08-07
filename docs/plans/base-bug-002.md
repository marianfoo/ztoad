# BASE-BUG-002 plan: generate aggregate CASE result types

## Goal

Make the `SUM( CASE ... END ) AS ...` form reported in GitHub issue #7 produce a valid generated subroutine pool while preserving existing aggregate behavior, authorization, injection controls, ABAP 7.50 compatibility, and ALV field metadata.

## Scope

- In scope: simple and searched CASE inside `SUM`, a direct qualified or unqualified DDIC column at the start of a result branch, alias metadata, focused parser/generator characterization, and exact A4H validation.
- Out of scope: arbitrary SQL-expression type inference, nested built-in-function support, generic select-list tokenization, executing the reported business query, provisioning ZTOAD on NPL, or resolving other open function/parser issues.

## TDD and implementation sequence

1. Replay the test-only red candidate on the final integrated base: the added `GENERATES_CASE_SUM_EXPRESSION` test must be the only failure, and no SQL may execute. The earlier 55/56 result is historical evidence, not a substitute for this rerun.
2. Add a small pure select-expression analyzer with tests for simple CASE, searched CASE, qualified/unqualified results, quoted `THEN` lookalikes (including spaces and doubled quotes), and an unprovable literal result.
3. During existing aggregate-token collection, ask the analyzer for the first provable CASE result-column reference. Keep the original SELECT text unchanged.
4. Feed the proven reference through the existing table-alias/DDIC type path. For CASE aggregates, keep the SQL alias as display metadata instead of claiming that the computed value is the physical source field.
5. Extend the generator helper/test to assert a generated pool, strict/new syntax, table-result mode, and alias-preserving field metadata. Add a searched-CASE generator regression and retain all earlier aggregate/security tests.
6. Run configured abaplint, repository-contract checks, the full diagnostic lint inventory, and `git diff --check`. Review touched code against Clean ABAP without mass-refactoring the legacy report.
7. Deploy the exact source to A4H through ARC-1 with server preflight and explicit activation. Run active syntax, all ABAP Unit tests with coverage, object-state comparison, both recorded ATC variants, and a safe FLP/editor startup plus ST22 delta without SQL execution.
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
- A local integration branch now applies the focused test and implementation commits on top of final green PR #24 head `d141aeb`; configured abaplint, repository/install contracts, `npm ci`, and `git diff --check` are green.
- Detailed review added two adversarial regressions. The inherited space-split analyzer would stop at `THEN` inside `'X THEN Y'` or `'X'' THEN Y'`; a quote-aware literal masker now removes literal contents before token analysis and handles doubled quotes without rewriting executable SQL.
- Prepared source commit `f89d53b` has SHA-256 `e08fe56796bcc8183d5354c0317ac9b2bc7d77345c31bd36b747f01e0bbb5578`. The diagnostic quality inventory is 2,169 findings across 63 rules versus 2,109/61 on PR #24; it is non-blocking but must be recomputed on final master.
- Nothing from this preparation has been pushed to PR #21 or deployed to SAP. After PR #24 merges, rebase deliberately, verify that the source hash remains exact or discard it, replay the 57/58 original red and 65/67 adversarial red candidates, then run all final live gates. Until then, previous A4H evidence is research history only.
