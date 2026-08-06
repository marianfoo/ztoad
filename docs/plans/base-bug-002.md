# BASE-BUG-002 plan: generate aggregate CASE result types

## Goal

Make the `SUM( CASE ... END ) AS ...` form reported in GitHub issue #7 produce a valid generated subroutine pool while preserving existing aggregate behavior, authorization, injection controls, ABAP 7.50 compatibility, and ALV field metadata.

## Scope

- In scope: simple and searched CASE inside `SUM`, a direct qualified or unqualified DDIC column at the start of a result branch, alias metadata, focused parser/generator characterization, and exact A4H validation.
- Out of scope: arbitrary SQL-expression type inference, nested built-in-function support, generic select-list tokenization, executing the reported business query, provisioning ZTOAD on NPL, or resolving other open function/parser issues.

## TDD and implementation sequence

1. Preserve the test-only red evidence: 55/56 A4H tests pass and only `GENERATES_CASE_SUM_EXPRESSION` fails; no SQL is executed.
2. Add a small pure select-expression analyzer with tests for simple CASE, searched CASE, a quoted `THEN` lookalike, and an unprovable literal result.
3. During existing aggregate-token collection, ask the analyzer for the first provable CASE result-column reference. Keep the original SELECT text unchanged.
4. Feed the proven reference through the existing table-alias/DDIC type path. For CASE aggregates, keep the SQL alias as display metadata instead of claiming that the computed value is the physical source field.
5. Extend the generator helper/test to assert a generated pool, strict/new syntax, table-result mode, and alias-preserving field metadata. Add a searched-CASE generator regression and retain all earlier aggregate/security tests.
6. Run configured abaplint, repository-contract checks, the full diagnostic lint inventory, and `git diff --check`. Review touched code against Clean ABAP without mass-refactoring the legacy report.
7. Deploy the exact source to A4H through ARC-1 with server preflight and explicit activation. Run active syntax, all ABAP Unit tests with coverage, object-state comparison, both recorded ATC variants, and a safe FLP/editor startup plus ST22 delta without SQL execution.
8. Reconfirm the 7.50 limitation through ARC-1/ADT only. If ZTOAD remains absent on NPL, record the existing prerequisite blocker rather than claiming a live pass.
9. Review the implementation, security boundaries, test names, documentation placement, and development process. Move this plan to `docs/plans/finished/`, update the findings register, and publish a ready PR only after all applicable gates pass.
10. Wait for required GitHub checks. If workflows fail before repository checkout, diagnose and distinguish GitHub infrastructure from product/CI defects before rerunning.

## Review criteria

- The analyzer returns only a restricted DDIC column token and never rewrites executable SQL.
- A quoted keyword or non-column result cannot be mistaken for a type reference.
- Unsupported CASE result forms fail through the existing no-program contract.
- Generated-program syntax remains the final proof that the chosen result target is compatible with the complete CASE expression.
- Existing direct fields, `COUNT`, `AVG`, simple `SUM`/`MAX`/`MIN`, top-level CASE, strict clause ordering, authorization, input validation, and line-boundary tests stay green.
- The patch introduces no post-7.50 production syntax and does not weaken configured abaplint.

