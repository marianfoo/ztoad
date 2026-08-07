# BASE-BUG-003 ABAP SQL function research

_Date: 2026-08-07 · finding: `BASE-BUG-003` · GitHub issue: #4_

## Reproduced failure

`QUERY_PARSE` extracts the SELECT list successfully. `QUERY_GENERATE` then creates a second, inference-only representation for the generated result structure. For strict syntax it translates every comma to a blank and splits the result at whitespace.

That transformation loses SQL grammar. In `SUBSTRING( DD03L~FIELDNAME, 1, 3 )`, the argument commas belong to one expression, but the inference copy treats them like result-column separators. The first token, `SUBSTRING(`, then falls through to the simple-field path and is emitted as an invalid DDIC component reference. Nested functions and literals containing commas fail at the same boundary. `LENGTH` has no comma, so `QUERY_PARSE` does not even select the strict 7.50 clause order.

The executable SELECT text is not the damaged representation; the broken copy is used only for result-component and ALV metadata inference. The fix therefore belongs at this boundary and must keep the validated executable SQL unchanged.

## SAP language contract

The SAP 7.50 release notes and strict-mode reference introduce `CONCAT`, `LPAD`, `LENGTH`, `LTRIM`, `REPLACE`, `RIGHT`, `RTRIM`, and `SUBSTRING`. Their use activates the 7.50 strict syntax check, including the requirement that `INTO` be the final SELECT clause.

SAP defines function arguments as comma-separated SQL expressions and permits expressions, including nested functions, as arguments. The result is a Dictionary type. For the 7.50 family, `LENGTH` returns `INT4`; the other selected functions return character-like results whose exact type and length can depend on their arguments. A generated `TYPE string` component is a safe receiving type for the character-like results and avoids pretending that the legacy parser has proven an exact DDIC type.

## Options evaluated

### Continue replacing every comma and add keyword exceptions

Rejected. Once the transformation has collapsed result separators, function separators, and literal data, later exceptions cannot reconstruct the grammar reliably.

### Replace the complete generator with inline result inference

Deferred. This could eventually remove much of the manual result typing, but it would change the ALV, count, aggregate, and legacy compatibility paths together. That is too broad for issue #4.

### Implement a complete cross-release SELECT-list grammar

Deferred to parser modernization. A complete grammar would need casts, arithmetic, CASE, aggregates, aliases, path expressions, legacy space-separated lists, and release-specific functions.

### Add a quote- and parenthesis-aware inference scanner

Selected. A small pure local class can preserve commas inside literals and nested expressions, replace only top-level item commas in the inference copy, recognize the supported 7.50 family outside literals, and fail closed on unbalanced input. The generator can then add one focused path for top-level supported function results while leaving the original SELECT text and existing security boundaries unchanged.

## Security and representation review

`LCL_QUERY_INPUT_VALIDATOR` and `LCL_SQL_SOURCE_SCANNER` remain the input and source-authorization boundaries. The new scanner must not relax either one and must never add characters to the executable SELECT.

The representation invariant is: only a comma at parenthesis depth zero and outside a quoted literal may become an inference separator. Parentheses and doubled single quotes must balance before an expression is accepted. Function-like text inside a literal must not enable strict mode. Unbalanced input fails before `GENERATE SUBROUTINE POOL`.

The 255-character generated-line splitter still receives the original SELECT text. This fix therefore adds no new source-wrapping, comment-column, or quote-boundary behavior.

## Red evidence

Test-only candidate `f75fad1cc5c4db61a959053591473cb60a68c781` has local source SHA-256 `5b7f042d1dd4fb185b48d0584a05a36e0985be2d9349888baf9bb6b27e5cd974`.

On NPL/SAP_BASIS 750, server preflight and explicit activation succeeded. Active and inactive main-source hashes matched at server-normalized SHA-256 `2a940658489e68b867072a54215e14a683506b4c7c3f2d5c7c4d34923eefee0c`, and no inactive ZTOAD object was returned. ABAP Unit ran 71 tests: all 67 inherited tests passed and exactly these four regressions failed:

- `GENERATES_SUBSTRING_FUNCTION`
- `GENERATES_NESTED_FUNCTIONS`
- `PRESERVES_FUNCTION_LITERAL`
- `GENERATES_LENGTH_FUNCTION`

No generated query was executed. The persistent ARC-1 MCP process still exposed its earlier package allowlist and blocked activation; the direct ARC-1 runner with the configured `*` allowlist activated and diagnosed the same object successfully. This is a stale-process tooling mismatch, not product evidence.

## Compatibility and code-quality assessment

The selected scanner uses local classes, strings, offsets, internal tables, and control flow available on SAP_BASIS 750. It introduces no new SAP API and no additional clean-core dependency. A pure parser class with focused ABAP Unit tests follows SAP Clean ABAP guidance to make logic testable and keep methods cohesive; it also incrementally separates new logic from the legacy procedural report, as recommended by the DSAG ABAP guide.

This change does not make dynamic subroutine generation clean-core compliant. It only makes the existing on-premise behavior correct and safer to maintain.

## Implemented boundary and final validation

The implementation adds a pure local select-list scanner and leaves the executable SELECT fragment unchanged. It replaces only top-level inference commas, recognizes the eight 7.50 functions outside literals, proves nested-expression closure, and rejects unbalanced or trailing expression syntax. The generator gives `LENGTH` an integer receiving component and the character-like family a string component while preserving an explicit SQL alias as ALV metadata.

The first green implementation added four `ABAP_CLOUD_READINESS` warnings through new test-local `SY-REPID` types. Replacing those test variables with compatible built-in character types removed the entire delta. The final candidate therefore remains exactly at master's 682 readiness findings instead of accepting avoidable test-code debt.

Final candidate `6a2971bded5ff273b82b1db4c4b15b84485612b6` passed 78/78 Unit tests, activation, syntax, object-state and inactive-part checks on both SAP_BASIS 750 and 758. NPL `DEFAULT` ATC remained 88 findings; A4H `ABAP_CLOUD_READINESS` remained 682. Fresh A4H WebGUI sessions returned five rows for both `SUBSTRING` and nested `CONCAT`/`SUBSTRING`, with the expected `PREFIX` and `LABEL` metadata and no new ST22 dump.

## Sources

- [ABAP 7.50 SQL changes](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENNEWS-750-ABAP_SQL.html)
- [ABAP 7.50 SQL strict mode](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENABAP_SQL_STRICTMODE_750.html)
- [ABAP SQL built-in functions](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_BUILTIN_FUNC.html)
- [ABAP SQL string functions](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_STRING_FUNC.html)
- [SAP Clean ABAP](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md)
- [DSAG ABAP guide: clean and modern ABAP](https://marianfoo.github.io/DSAG-ABAP-Guide/abap/clean_and_modern_abap/)
