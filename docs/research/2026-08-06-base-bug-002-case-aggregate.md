# BASE-BUG-002 research: aggregate CASE expressions

## Issue and observed behavior

[GitHub issue #7](https://github.com/marianfoo/ztoad/issues/7) reports that a select list containing `SUM( CASE ... END ) AS ...` fails with `No component exists with the name "CASE"`.

The repository regression uses the same grammar with harmless demo-table metadata:

```abap
SELECT SUM( CASE SFLIGHT~CARRID
              WHEN 'LH' THEN SFLIGHT~PRICE
              ELSE SFLIGHT~PRICE * -1
            END ) AS NET_PRICE,
       SFLIGHT~CARRID
  FROM SFLIGHT
 GROUP BY SFLIGHT~CARRID
```

The test calls the parser and generator only. It never invokes the generated subroutine and therefore executes no SQL.

## Root cause

`QUERY_GENERATE` uppercases the select list, changes top-level comma separators to spaces, and then splits the complete list at every space. Its `SUM`/`MAX`/`MIN` branch collects tokens until a closing parenthesis but assumes the first token after the aggregate opener is the DDIC field that determines the generated result component type.

For `SUM( CASE ... )`, the first token is `CASE`. The generator consequently attempts to declare a component such as `TYPE SFLIGHT-CASE` (or `TYPE EKBE-CASE` in the reported query). The generated-program syntax check correctly rejects that nonexistent component and returns no subroutine pool.

The exact test-only A4H candidate activated with zero syntax errors and two known POSIX warnings. ABAP Unit then passed 55 of 56 tests; only `LTC_QUERY_GENERATOR->GENERATES_CASE_SUM_EXPRESSION` failed because the generated program was initial. This proves the defect at the generator boundary without reading application data.

## SAP grammar and type rules

- [ABAP SQL aggregate functions](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_AGG_FUNC.html) allow an SQL expression as the argument of `SUM`; the SUM result has the DDIC type of that SQL expression.
- [Simple CASE](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_SIMPLE_CASE.html) and [searched CASE](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_SEARCHED_CASE.html) accept SQL expressions as result branches. Compatible branches produce a common result type.
- [SELECT-list column specifications](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPSELECT_CLAUSE_COL_SPEC.html) treat aggregate and CASE expressions as typed result columns and require a suitable target.
- The SAP feature matrix records Open SQL `CASE` as available from 7.40 SP08, including SAP_BASIS 750 and 758. No newer ABAP syntax is required for the fix.

An A4H source-only syntax spike confirmed the practical target constraint. The SFLIGHT CASE sum is valid with `TYPE SFLIGHT-PRICE` and with a compatible packed target, but not with a generic `DECFLOAT34` target. The exact issue table `EKBE` is unavailable in this A4H installation, so SFLIGHT is the portable live grammar/type proof.

## Options evaluated

### 1. Declare every CASE sum as string or decfloat34

Rejected. A string loses numeric semantics, and A4H rejects `DECFLOAT34` for the currency-typed SFLIGHT expression. Guessing a generic type would trade the current deterministic error for incompatible targets or silent conversion risk.

### 2. Infer the complete result table with inline `@DATA`

Deferred. SAP could infer the exact expression type, but ZTOAD currently adds a synthetic count component and builds ALV metadata around its explicit generated structure. Replacing that contract is a broad generator redesign and would increase regression risk for a focused bug fix.

### 3. Reuse the CASE selector column

Rejected. In the reported simple CASE, the selector is `EKBE~SHKZG` while the result is based on `EKBE~MENGE`; using the selector reproduces the wrong-type problem in a subtler form.

### 4. Resolve the first direct result column after THEN

Selected. A small pure analyzer can identify the first direct DDIC column that begins a CASE result branch. The existing DDIC/alias mapping can then declare the generated component with that type. SAP's generated-program syntax check remains the final compatibility proof for all CASE branches and rejects unsupported expressions before generation.

This deliberately supports direct qualified or unqualified result columns, including the reported `THEN EKBE~MENGE`. If no such reference can be proven, generation continues to fail closed. General SQL-expression tokenization, nested functions, and arbitrary result-type inference remain part of `BASE-BUG-003`/`BASE-BUG-004`, not this patch.

## Security and compatibility boundaries

- The original SQL text is not rewritten from the inferred reference; the reference is used only for the generated target type.
- The existing positive query-input policy, physical-source authorization scanner, safe 255-character splitter, generated-source syntax check, and no-program return guards remain in force.
- Both simple and searched CASE forms need tests, as do quoted `THEN` lookalikes and an unprovable literal-result form.
- The end-to-end generator regression must assert both successful pool generation and alias-preserving field metadata.
- NPL remains unavailable for exact ZTOAD validation because its PROG/TABL objects have not been provisioned. No NPL GUI fallback is permitted.

## 2026-08-07 integration review

The first quoted-keyword test used the one-token literal `'THEN'`. A whitespace splitter ignores that token because its quotes remain attached, but this did not prove literal awareness. Valid literals containing spaces expose the gap: both `'X THEN Y'` and the doubled-quote form `'X'' THEN Y'` produce a standalone `THEN` token, causing the analyzer to return before reaching the real CASE branch.

The integration candidate therefore masks complete single-quoted literals before looking for `CASE`/`THEN`, preserves outside characters and spacing, handles doubled SQL quotes, and returns no type reference for an unbalanced literal. Two focused analyzer regressions cover the spaced and doubled-quote lookalikes. This is a typing-only transformation; the original query text still reaches the existing validator, authorization scanner, and generated-source boundary unchanged.

PR #21 predates several merged report changes. Its earlier 55/56 red, 63/63 green, 668-finding ATC run, GUI-status limitation, and candidate hashes remain useful historical evidence but are not acceptance evidence for the rebased result. The final branch must replay red/green Unit evidence, exact activation/state, both ATC variants, WebGUI core smoke, ST22 delta, and master restoration after PR #24 has merged.

### Live representation-boundary correction

The first rebased implementation passed configured abaplint but failed eight of 67 live Unit tests. The masker appended `TYPE c LENGTH 1` characters with `&&`; ABAP removes trailing blanks from fixed-length character operands during that conversion. Consequently, every outside token separator and every masked literal character represented by a blank disappeared before `SPLIT ... AT space`, so no standalone `CASE` or `THEN` token remained.

This was not a SQL grammar defect. It was a representation mismatch between the local static model and ABAP string semantics. `CONCATENATE ... RESPECTING BLANKS` now preserves one output character per input character while masking literal contents. The pre-existing simple/searched/quoted/analyzer and generator tests turned from 59/67 to 67/67 without widening the supported grammar.

Exact candidate `36579848804e822f0863827479e221e3000231b5` (local source SHA-256 `8ac6f8ddc965c08d53f87995403c8271d4d95542d73d567387a222389a65283e`) activated on A4H with zero errors and two existing POSIX warnings. Active/inactive server source matched at `e32d7d3b8bebdb38457cd81f52e90a3b00dc0e830ac537b7690b70cee4544897`; all 67 tests passed, and the complete Cloud ATC inventory remained 682 findings (474 P1/208 P2). A marked fresh WebGUI session executed the sanitized SFLIGHT CASE aggregate, returned eight grouped rows, preserved the `NET_PRICE` heading, exited cleanly, and produced no ST22 delta.
