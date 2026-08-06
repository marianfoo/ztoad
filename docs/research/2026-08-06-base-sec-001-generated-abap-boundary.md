# BASE-SEC-001 generated ABAP boundary research

_Date: 2026-08-06 · finding: `BASE-SEC-001`_

## Revalidated exploit path

ZTOAD does not pass a dynamic token to one fixed ABAP SQL statement. `QUERY_GENERATE` and `QUERY_GENERATE_NOSELECT` concatenate parser output into an internal source table, run `SYNTAX-CHECK FOR`, and then call `GENERATE SUBROUTINE POOL`. A syntax check proves only that the result is valid ABAP; it does not prove that the result contains only the intended SQL statement.

For example, the SELECT tail `WHERE CARRID = 'LH'. WRITE sy-uname` closes the generated SELECT with the injected period. ZTOAD's own final period then closes `WRITE`, producing a valid generated program. The same boundary exists in UPDATE/DELETE parameter text. This can extend SQL input into arbitrary ABAP statements executed under the current user.

The existing parser removes a caller-provided `INTO` target before generation and intentionally accepts SQL expressions and literals. The security boundary therefore belongs immediately before generated source is created, after safe parser normalization but before any fragment is emitted.

## Security contract

- Parser output may describe one intended ABAP SQL statement only; it must not terminate that statement or introduce ABAP comments, host references, chained statements, string templates, or another source-language construct.
- Ordinary identifiers, aliases, SQL functions, parentheses, comparisons, arithmetic, wildcards, namespace slashes, and single-quoted SQL literals remain usable.
- A period is accepted only inside a single-quoted literal or between two digits in a decimal literal. A minus sign is accepted only for a numeric literal, not as an unescaped ABAP host-component selector such as `sy-uname`.
- Single-quoted literals must be balanced and doubled quotes remain valid.
- SELECT and generated INSERT/UPDATE/DELETE use the same validator at the last pre-generation boundary. Native SQL is outside this generated-program path and remains the independent `BASE-SEC-002` finding.
- Table-source authorization completeness remains the independent `BASE-SEC-003` finding. The validator prevents transition from SQL text into ABAP source; it does not invent a field-level authorization policy that ZTOAD does not have.

## Options evaluated

### Rely on `SYNTAX-CHECK FOR`

Rejected. The demonstrated payload is valid ABAP and is therefore accepted by exactly that check.

### Deny a short list of ABAP keywords

Rejected. ABAP and ABAP SQL share many words, and statement injection does not require one stable keyword. A deny list would be incomplete and difficult to review.

### Replace generation with fully dynamic ABAP SQL

Deferred. It would reduce the generic-programming risk but requires a larger parser/result-type redesign and would overlap the open parser architecture findings. It is not the smallest safe P0 patch.

### Validate the emitted-fragment alphabet and literal state

Selected. A pure local validator recognizes the small set of characters required by the supported SQL surface, handles single-quoted literals and decimals explicitly, and rejects source-language boundary characters before either generator emits a line. This is an include-list approach at the ABAP-source boundary, not a claim to implement the complete ABAP SQL grammar.

## Test design

- Red: prove the original SELECT and UPDATE generators both create a subroutine pool from a payload that closes the SQL statement and appends `WRITE sy-uname`; do not execute either generated pool.
- Green: reject statement terminators, comments, host escapes, unbalanced quotes, backtick/template literals, chained-statement punctuation, and `sy-...` host-component syntax.
- Preserve: simple SELECT, joins, aggregates, comparisons, decimal and negative numeric literals, namespace names, doubled single quotes, SQL wildcard/multiplication, and parser-stripped caller `INTO` syntax.
- Regression: run the complete local and A4H suite; no malicious SQL or generated pool is executed.

## Compatibility and Clean Core

The validator uses a pure local class, classic string offsets, and `CL_ABAP_CHAR_UTILITIES` constants available at the SAP_BASIS 750 floor. It adds no database or frontend dependency. The generic subroutine-pool architecture remains classic/unclean-core debt, but the input-to-source transition now has an explicit fail-closed contract.

## SAP sources

- [SQL Injections in Generated Programs](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_INJ_GEN_PROG_SCRTY.html) calls generic programming the least safe dynamic technique and requires external values embedded into generated code to be escaped.
- [SQL Injections in Dynamic Tokens](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_INJ_DYN_TOKENS_SCRTY.html) requires external table/column/condition input to be checked with include lists and values to be escaped or bound.
- [Dynamic Programming Security](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENDYNAMIC_PROGRAMMING_SCRTY.html) treats injected full statements, statement parts, and dynamically named objects as distinct trust boundaries.
