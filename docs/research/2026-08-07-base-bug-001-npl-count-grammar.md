# BASE-BUG-001: SAP_BASIS 750 aggregate fixture investigation

_Research date: 2026-08-07 · system: NPL client 001 · release: SAP_BASIS 750 SP02_

## Outcome

The complete offline abapGit installation removed the former NPL prerequisite block and exposed one red test. The strict aggregate production fix is not the failing grammar boundary: the regression fixture uses `COUNT( FIELDNAME )`, which the NPL 7.50 compiler rejects.

Changing the fixture to `COUNT( DISTINCT FIELDNAME )` preserves the original `BASE-BUG-001` clause-order scenario and compiles on SAP_BASIS 750.

## Exact installed baseline

- Git source: `origin/master` commit `d532b2ec8d7a25fabed457bb2f660504636d424f`
- Local source SHA-256: `8ac6f8ddc965c08d53f87995403c8271d4d95542d73d567387a222389a65283e`
- NPL server-normalized active/inactive SHA-256: `e32d7d3b8bebdb38457cd81f52e90a3b00dc0e830ac537b7690b70cee4544897`
- SAP syntax: zero errors
- ABAP Unit: 66 passed, one failed
- Failed method: `LTC_QUERY_GENERATOR->GENERATES_STRICT_AGGREGATE`
- ATC `DEFAULT`: 88 findings (3 priority 1, 4 priority 2, 81 priority 3)
- Inactive inventory: no ZTOAD object or composite child part

The local/server hash pair was already established for this source representation on A4H. The byte difference is SAP line-ending/source normalization, not a source-content difference.

## Compiler probes

All probes used ARC-1 `SAPDiagnose(action="syntax", source=...)`; they did not write an SAP object.

| Expression or query | NPL result |
|---|---|
| `COUNT( FIELDNAME )` | Grammar error at `FIELDNAME` |
| `COUNT(FIELDNAME)` | Parsed as an unknown column name |
| `COUNT( DISTINCT FIELDNAME )` | Pass |
| `COUNT( * )` | Pass |
| Complete original fixture with `INTO` at the end | Same `FIELDNAME` grammar error |
| Complete original fixture with `INTO` before `FROM` | Same `FIELDNAME` grammar error |
| Complete fixture with both counts changed to `COUNT( DISTINCT FIELDNAME )` | Pass |

The identical failure with both `INTO` placements proves that this red result cannot validate or invalidate the original clause-order fix.

## Documentation check

The SAP Docs MCP aggregate short reference documents the current grammar as `COUNT( [DISTINCT] sql_exp )` plus `COUNT( * )`. That latest reference is useful for explaining why the original fixture works on A4H 758, but it is not evidence that every form exists on 7.50. The live 7.50 compiler is authoritative for the compatibility floor and demonstrates the narrower accepted grammar.

Reference: [SAP ABAP aggregate-expression short reference](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENAGGREGATE_SHORTREF.html)

## Test-design decision

`generates_strict_aggregate` protects these properties:

- comma syntax selects the strict Open SQL generator path;
- the result follows the table-result path;
- a grouped aggregate with `HAVING` and `ORDER BY` produces a valid generated pool;
- `INTO TABLE` remains in the strict-syntax position accepted by the compiler.

Adding `DISTINCT` inside both `COUNT` expressions does not weaken any of those properties. It removes an unrelated release-specific grammar dependency and makes the regression portable to the documented SAP_BASIS 750 floor.

## Separate installation finding

NPL activated table `ZTOAD` with an enhancement-category warning and normalized it to `#NOT_CLASSIFIED`, leaving a table serialization difference. That is a structural metadata issue and must be addressed through a separate native-abapGit round trip; it is not part of this test-only correction.
