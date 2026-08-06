# BASE-SEC-001 generated ABAP boundary research

_Date: 2026-08-06 · finding: `BASE-SEC-001`_

## Revalidated exploit path

ZTOAD does not pass a dynamic token to one fixed ABAP SQL statement. `QUERY_GENERATE` and `QUERY_GENERATE_NOSELECT` concatenate parser output into an internal source table, run `SYNTAX-CHECK FOR`, and then call `GENERATE SUBROUTINE POOL`. A syntax check proves only that the result is valid ABAP; it does not prove that the result contains only the intended SQL statement.

For example, the SELECT tail `WHERE CARRID = 'LH'. WRITE sy-uname` closes the generated SELECT with the injected period. ZTOAD's own final period then closes `WRITE`, producing a valid generated program. The same boundary exists in UPDATE/DELETE parameter text. This can extend SQL input into arbitrary ABAP statements executed under the current user.

`EDITOR_GET_QUERY` currently treats a top-level period as a query separator and normally removes it before parsing. That reduces direct reachability of this exact payload from the current editor, and this research does not claim that the demonstrated string is an end-to-end UI exploit today. It is not a sufficient sink-side security invariant: the generator FORMs accept the fragment, parser/selection behavior is already tracked as defective, and any alternate/internal caller or future parser correction would expose valid injected ABAP. The durable control belongs at the generator boundary that can actually create executable source.

The existing parser removes a caller-provided `INTO` target before generation and intentionally accepts SQL expressions and literals. The security boundary therefore belongs immediately before generated source is created, after safe parser normalization but before any fragment is emitted.

## Security contract

- Parser output may describe one intended ABAP SQL statement only; it must not terminate that statement or introduce ABAP comments, host references, chained statements, string templates, or another source-language construct.
- Ordinary identifiers, aliases, SQL functions, parentheses, comparisons, arithmetic, wildcards, namespace slashes, and single-quoted SQL literals remain usable.
- A period is accepted only inside a single-quoted literal or between two digits in a decimal literal. A minus sign is accepted only for a numeric literal, not as an unescaped ABAP host-component selector such as `sy-uname`.
- ABAP SQL type namespaces such as `abap.dec` currently fail closed. Safely preserving them requires grammar-aware recognition of a CAST type position; accepting any apparent `ABAP.<word>` sequence would weaken the statement-terminator invariant.
- Single-quoted literals must be balanced and doubled quotes remain valid.
- Generated source wrapping must preserve that character-level interpretation. Lines may split only at whitespace outside a literal; a required hard cut, a split inside a literal, or a continuation that would move `*` into ABAP source column one fails before generation.
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

### Preserve semantics across generated-line wrapping

Selected after external review. The procedural line splitter previously preferred any whitespace and otherwise cut at exactly 255 characters without tracking literal state. A live test placed the two quotes of one SQL `''` escape on opposite sides of that cut. The fragment validator accepted the balanced literal and the generated source passed `SYNTAX-CHECK`, producing a subroutine pool. No pool or SQL was executed, so this proves a representation change and executable output, not a demonstrated end-to-end data exploit.

`LCL_GENERATED_LINE_SPLITTER` now accepts only whitespace outside a single-quoted literal. If no such boundary exists inside 255 characters, generation fails closed instead of cutting the token. It also rejects a split that would move `*` into source column one, where ABAP would interpret it as a full-line comment. `*` remains allowed for SQL wildcards, `COUNT( * )`, and multiplication when its generated position is stable. Very long unbroken tokens or literals that cannot be represented without an unsafe split are an intentional fail-closed limitation.

## Test design

- Red: prove the original SELECT and UPDATE generators both create a subroutine pool from a payload that closes the SQL statement and appends `WRITE sy-uname`; do not execute either generated pool.
- Green: reject statement terminators, comments, host escapes, unbalanced quotes, backtick/template literals, chained-statement punctuation, and `sy-...` host-component syntax.
- Adversarial: reject an `AS ABAP.WRITE ...` lookalike so a namespace-shaped token cannot reintroduce a general period exception.
- Representation boundary: place a doubled quote exactly across the old 255-character hard cut and require no pool; reject unbroken overlength lines and any split that would move `*` into column one while preserving ordinary safe whitespace wrapping.
- Error contract: invalid but allow-listed DML syntax must clear the pool handle and return like the SELECT sink instead of relying on a dialog `E` message to abort control flow.
- Preserve: simple SELECT, joins, aggregates, comparisons, decimal and negative numeric literals, namespace names, doubled single quotes, SQL wildcard/multiplication, and parser-stripped caller `INTO` syntax.
- Regression: run the complete local and A4H suite; no malicious SQL or generated pool is executed.

## Compatibility and Clean Core

The validator and quote-aware splitter use classic string offsets and `CL_ABAP_CHAR_UTILITIES` constants available at the SAP_BASIS 750 floor. They add no database or frontend dependency. The generic subroutine-pool architecture remains classic/unclean-core debt, but the input-to-source transition now has an explicit fail-closed contract before and after line representation.

## SAP sources

- [SQL Injections in Generated Programs](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_INJ_GEN_PROG_SCRTY.html) calls generic programming the least safe dynamic technique and requires external values embedded into generated code to be escaped.
- [SQL Injections in Dynamic Tokens](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_INJ_DYN_TOKENS_SCRTY.html) requires external table/column/condition input to be checked with include lists and values to be escaped or bound.
- [Dynamic Programming Security](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENDYNAMIC_PROGRAMMING_SCRTY.html) treats injected full statements, statement parts, and dynamically named objects as distinct trust boundaries.
