# BASE-BUG-005: UNION execution

Date: 2026-08-07

## Finding

`QUERY_PARSE` recognizes only a top-level `UNION SELECT` spelling. It returns
the right `SELECT` without the set operator, after which `QUERY_PROCESS`
generates and executes each branch independently and appends the generic
internal tables. This has three separate correctness defects:

- implicit `UNION DISTINCT` semantics are lost because ABAP `APPEND` does not
  remove duplicates;
- branch layouts are never checked as one SQL set, so an incompatible right
  result can reach a generic table append;
- `UNION ALL` does not enter that path and instead leaks into the first
  generator invocation, where target-clause placement is invalid.

Whitespace, line breaks, and the explicit `DISTINCT` modifier widen the split
gap. A row restriction before a later branch is also accepted as if it were a
global result cap.

## Official language contract

The Standard ABAP SQL reference defines `UNION [ALL|DISTINCT]` between complete
queries. `DISTINCT` is the default; it removes duplicate rows across the
existing left result and the right result, while `ALL` preserves them. All
branch select lists must contain the same number of elements with compatible
types. The target belongs at the end of the complete set expression.

The same reference says `UP TO` cannot be combined directly with a set
expression. `OPEN CURSOR` accepts a set expression without a target, and
`FETCH NEXT CURSOR ... INTO TABLE ... PACKAGE SIZE n` reads at most the requested
number of rows. This provides a platform-owned set operation while retaining
ZTOAD's default or explicit result cap.

Sources:

- [ABAP SQL set operators](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPUNION.html)
- [Set-query clause and layout rules](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPUNION_CLAUSE.html)
- [OPEN CURSOR query clauses](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPOPEN_CURSOR_MAINQUERY.html)
- [FETCH and PACKAGE SIZE](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPFETCH.html)

## Read-only compiler probes

The following probes were compiled without writing source on both supported
targets:

| Probe | SAP_BASIS 750 | S/4HANA 2023 |
|---|---|---|
| Standalone `UNION` plus `UP TO` | rejected: `UP TO n ROWS` cannot be used in `UNION` | same |
| `OPEN CURSOR` over `UNION`, limited by `FETCH ... PACKAGE SIZE` | clean | clean |
| `OPEN CURSOR` over `UNION ALL`, limited by `FETCH ... PACKAGE SIZE` | clean | clean |
| Mismatched one-column/two-column branches | rejected with an exact branch-element-count error | same |

This proves the proposed representation on the compatibility floor instead of
inferring support from current documentation alone.

## Red replay

Test-only commit `c39d1d0` was activated on SAP_BASIS 750 with the original
production implementation. ABAP Unit ran 97 tests: 89 unchanged tests passed
and exactly eight intended assertions failed:

- parser: preserve `UNION`, preserve `UNION ALL` with line-break/space
  variation, and reject a limit before a later branch;
- generator/runtime: execute implicit-distinct and `ALL` sets as one query,
  reject mismatched layouts, and cap the merged result.

No production behavior was changed in the red commit.

## Selected approach

Preserve the complete top-level set suffix, including its operator and optional
modifier. Reconstruct one validated SQL set expression and let SAP compile and
execute it through `OPEN CURSOR`. Fetch the first configured number of rows
using `PACKAGE SIZE`; a final ZTOAD `UP TO n ROWS` remains a result cap, whereas
an `UP TO` followed by another set branch fails closed.

The existing full-query source scanner remains the authorization boundary for
every physical source. Literal and nested lookalikes stay masked by the
same-length structural scanner. No branch is executed or appended separately.

## Alternatives rejected

- **Keep branch-by-branch execution and add an ABAP de-duplication pass.** This
  would still need a trustworthy common row type, would duplicate database set
  semantics, and would leave ordering/type conversion behavior ambiguous.
- **Execute the set once and delete rows beyond the cap afterward.** This does
  not bound database transfer or ABAP memory and breaks the product's safety
  contract.
- **Wrap the set in a derived table or CTE and apply `UP TO`.** The 7.50 floor
  does not provide a suitable portable derived-table form for this use.
- **Reject all set queries.** Safe, but unnecessary because the cursor form is
  accepted by both supported compilers and preserves the advertised feature.

## Implemented behavior

`LCL_SQL_SET_EXPRESSION` now owns the shared set pattern, suffix attachment,
and source reconstruction. `QUERY_PARSE` moves global limit/target handling in
front of the set split, preserves `UNION`, `UNION DISTINCT`, and `UNION ALL`,
and rejects both a branch-local limit and `SELECT SINGLE` combined with a set.
The authorization scanner still receives the complete set before generation.

`QUERY_PROCESS` generates one program for the reconstructed expression. At the
sink, a top-level set uses `OPEN CURSOR`, one bounded `FETCH ... PACKAGE SIZE`
for a positive cap (or the existing unlimited fetch for explicit zero), and an
explicit cursor close. SAP therefore owns duplicate removal/preservation and
branch-layout compatibility. The former generic-table append loop is gone.

The first live green replay exposed one additional representation boundary:
the `SELECT SINGLE` guard sliced a `TYPE string` into a fixed-length character
operand, whose blank comparison behaved differently from the local static
model. The final guard uses an explicit `TYPE c LENGTH 7` token and has its own
red/green SAP_BASIS 750 regression. This confirms that token-boundary behavior
must be replayed on the compatibility-floor compiler even when abaplint is
green.

## Final verification

The exact candidate is commit
`58aed8d443d3837bdc94b579e0b4f6b5bfba96df`, local source SHA-256
`9848ace8fadb61ef72a0a28a7ee011e72d8e58ebebad4514d3268eafcb940a2e`.
Both systems normalized the active and inactive source to SHA-256
`7ab32de5518a77c996e6dc1341618df4480c928ebd6529c63a918ab199e54d63`.

- Local configured abaplint, repository contract, installation contract, and
  complete test command passed.
- NPL activated with zero syntax messages, 106/106 Unit tests, no inactive
  ZTOAD part, and 86 complete DEFAULT ATC findings (3 P1, 4 P2, 79 P3).
- A4H activated with zero syntax errors and the inherited seven POSIX-regex
  warnings, 106/106 Unit tests, and no inactive ZTOAD part.
- A4H `ABAP_CLOUD_READINESS` completed with 697 findings (487 P1, 210 P2).
  The delta is report-local test code and remains tracked by the planned global
  class/test-include extraction. The S/4HANA readiness variant returned no
  rows but remains prerequisite-incomplete.
- A fresh WebGUI session executed a real user-typed read-only two-branch
  `UNION ALL` aggregate with a final cap of one. The success state reported one
  result row, and a client-side comparison of the complete ST22 result sets
  found no new dump.
