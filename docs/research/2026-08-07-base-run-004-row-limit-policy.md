# BASE-RUN-004 — bounded SELECT result policy

_Date: 2026-08-07_

## Question

How should ZTOAD handle `UP TO 0 ROWS`, invalid or oversized explicit limits,
and a saved default of zero without allowing an accidental unbounded result on
the SAP_BASIS 750 compatibility floor?

## SAP runtime contract

The official ABAP keyword documentation says that `UP TO n ROWS` limits a
result set to `n`, but a runtime value of zero means a maximum of
2,147,483,647 rows. A positive value is the actual maximum. The documentation
also notes that a literal or constant zero is rejected only in strict mode from
ABAP release 7.63; that newer compiler rule is not a portable safety control for
ZTOAD's SAP_BASIS 750 floor.

Source: [SAP ABAP Keyword Documentation — `SELECT, UP TO, OFFSET`](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPSELECT_UP_TO_OFFSET.html), retrieved through the SAP documentation MCP server on 2026-08-07.

## Repository trace and root cause

- The help text explicitly advertises `UP TO 0 ROWS` as the way to disable the
  result limit.
- `QUERY_PARSE` extracts the zero, assigns it to the numeric `fw_rows`, and
  removes the clause from the user query.
- All three emitted representations interpret an initial `fw_rows` as "do not
  emit a cap": legacy `SELECT`, strict `SELECT`, and the set-query cursor
  `FETCH ... PACKAGE SIZE` path.
- The saved `MAXROWS` option has the same bypass: a configured value of zero is
  used when a query has no explicit limit, then the generator omits the cap.
- The row token regex accepts arbitrarily many digits before assigning to a
  six-character numeric destination, and unsupported forms are left for a later
  compiler failure instead of being decided by one product policy.
- A result cap protects application-server result memory and ALV transfer. It
  does not generally bound database work performed before the cap, such as an
  aggregate, sort, or join. Database hints are vendor-specific, and no portable
  SAP_BASIS 750 ABAP SQL per-statement timeout was found. ZTOAD must not claim
  that a row ceiling is a general query-cost governor.

The root cause is therefore the use of ABAP's initial numeric value as both a
legitimate user request and the internal sentinel for "omit the cap", with no
central range policy before the parser-to-generator boundary.

## Red reproduction

Both systems were first aligned to merged master `ef54657`: NPL passed clean
syntax, 113/113 ABAP Unit, equal active/inactive source, no inactive ZTOAD part,
and complete DEFAULT ATC at 85 findings (P1 3, P2 4, P3 78). A4H passed syntax
with the seven known POSIX warnings, 113/113 ABAP Unit, equal source, no inactive
ZTOAD part, and complete ABAP_CLOUD_READINESS at 709 findings (P1 490, P2 219).

Red commit `ccea89741a3317de361c54b081c657def4ee9899` changes only the
existing zero-limit characterization into the required fail-closed assertion.
The exact source is syntax-valid on NPL and runs 113 tests: 112 pass and only
`LTC_QUERY_PARSER->REJECTS_ZERO_LIMIT` fails. No SELECT is executed and no
unbounded result is materialized.

## Options considered

1. **Keep unlimited mode behind a confirmation.** This catches some accidental
   clicks but still allows a single dialog process to request essentially all
   matching rows. It also adds UI-dependent policy to a parser invariant.
2. **Silently reinterpret explicit zero as the normal default.** This is bounded
   but hides that the query did not mean what the user wrote.
3. **Reject unsafe explicit limits and always resolve defaults to a bounded
   value.** This is recommended. Explicit zero, nonnumeric values, and values
   above the ceiling fail before generation. Missing or invalid persisted
   defaults recover safely so an old user parameter cannot disable the limit.

## Recommended invariant

Every executable multirow SELECT representation receives a positive ZTOAD row
limit from 1 through 10,000. An explicit request outside that range is rejected
before generation. A missing, zero, or negative saved default resolves to the
product fallback of 100; a saved default above 10,000 is capped at 10,000.
`SELECT SINGLE` remains one row. Standalone aggregate results may still require
database work before returning their bounded result, so expensive-query control
remains an operational authorization/database-workload concern rather than a
false promise made by this result policy.

The policy should be a small pure local class used once at the parser boundary.
Tests must cover the default, zero, negative/nonnumeric, overflow, exact maximum,
above maximum, leading zeros, literal lookalikes, strict generation, and set
cursor generation. No test should deliberately retrieve a large result.

## Compatibility and safety

- The implementation needs only strings, integers, constants, comparisons, and
  local class methods supported on SAP_BASIS 750.
- The maximum is a ZTOAD product policy, not an SAP platform limit.
- Rejecting explicit zero is a deliberate behavior change. README and embedded
  help must stop advertising unlimited mode.
- Live validation should submit a zero-limit read-only query and prove rejection
  before generation, then submit a small positive-limit query and prove the
  requested row count, followed by a complete ST22 delta.
- No persistent data, destructive SQL, or intentionally heavy query is needed.
