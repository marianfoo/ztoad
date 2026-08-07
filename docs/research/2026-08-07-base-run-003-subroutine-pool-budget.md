# BASE-RUN-003 — temporary subroutine-pool budget

_Date: 2026-08-07_

## Question

How can ZTOAD prevent repeated interactive queries from exhausting the finite
`GENERATE SUBROUTINE POOL` directory without hiding the problem behind a
restart message or creating a destructive stress test?

## SAP runtime contract

The official ABAP keyword documentation states that:

- a temporary subroutine pool is stored in the current internal session;
- an internal session can contain at most 36 temporary subroutine pools;
- a created pool cannot be deleted explicitly and lives until the internal
  session closes;
- a generation exception returns `sy-subrc = 8`, but SAP still performs a
  database rollback and stores the corresponding short dump; and
- `GENERATE SUBROUTINE POOL` is intended only for exceptional application use.

Source: [SAP ABAP Keyword Documentation — `GENERATE SUBROUTINE POOL`](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPGENERATE_SUBROUTINE_POOL.html), retrieved through the SAP documentation MCP server on 2026-08-07.

The limit is therefore an admission-control concern. Catching or formatting a
generation error after the 37th request is too late to satisfy the no-dump and
no-rollback invariant.

## Repository trace and root cause

- The initial repository commit used `c_query_max_exec = 36`.
- Commit `cc2ff8cf` changed the value to `1000` as part of version 4.0.3,
  without a matching runtime-lifecycle change.
- `QUERY_PROCESS` currently compares the global `w_run` counter with that
  value before calling either generator.
- The counter is incremented outside the generator whenever a program name is
  returned. The generator itself is the only reliable place that knows whether
  a real pool was created.
- The generated-code display route passes through the same outer counter gate.
  Although `EDITOR-CALL` creates no pool, the surrounding orchestration is
  coupled to the execution counter.
- DML generation happens before `POPUP_TO_CONFIRM`. Cancelling a DML request
  therefore leaves an undeletable temporary pool in the session.
- Both SELECT and DML generator sinks are protected against an initial program
  handle after `BASE-RUN-002`, but a generation error can still produce the SAP
  side effects documented above.

The defect is not a missing cleanup statement: SAP provides no deletion API.
The root cause is that ZTOAD admits far more generated pools than the runtime
can hold and allocates them before it knows that execution is wanted.

## Red reproduction

Current `master` (`b0b4d9f`) was activated on both supported systems first.
Both passed active syntax, 109/109 ABAP Unit tests, active/inactive source
equality, and the inactive-object inventory contained no ZTOAD part.

Red commit `9b98a2d904825136e55a86d55ca1e1ce31cd3ecd` adds only
`LTCL_SUBROUTINE_POOL_BUDGET->STAYS_BELOW_SYSTEM_LIMIT`. On NPL/SAP_BASIS 750,
the exact source activated and ran 110 tests: 109 passed and this one failed
because the configured 1,000-run limit is greater than SAP's 36-pool maximum.
No pools were deliberately exhausted and no dump was required to prove the
invalid invariant.

## Options considered

1. **Restore an exact limit of 36.** This blocks a ZTOAD-owned 37th generation
   in an otherwise empty internal session, but leaves no allowance for another
   component in the same session. It also does not fix display accounting or
   pools allocated before a cancelled DML request.
2. **Use a defensive ZTOAD limit of 30 and reserve six session slots.** This is
   the recommended bounded mitigation. It cannot discover pools created by
   unrelated code, so it is deliberately described as a reserve rather than a
   proof that the whole session is empty.
3. **Replace generated programs with a reusable typed execution architecture.**
   This is the strongest long-term design and aligns with the incremental OO
   goal, but dynamic result typing makes it an architectural project rather
   than the smallest safe fix for this finding. It remains under the existing
   architecture findings.

## Recommended invariant

ZTOAD may successfully create at most 30 temporary pools in one report session.
Admission stops before generation when that budget is spent. Only a successful
real generation charges the counter; source display, rejected source, failed
generation, and cancelled DML do not. The six-slot reserve is explicit and
testable, while SAP's absolute 36-pool limit remains visible in code.

A pure local policy class should model the boundary so ABAP Unit can exercise
more than 36 logical attempts without consuming any temporary SAP pool. The two
existing generator sinks remain the runtime enforcement points. DML confirmation
must precede the allocating generator call.

## Compatibility and limits

- The policy needs only constants, integer comparison, class methods, and
  `abap_bool`, all supported on SAP_BASIS 750.
- This is classic on-premise dynamic ABAP and makes no ABAP Cloud/Clean Core
  compliance claim.
- The mitigation bounds ZTOAD-owned pools; it cannot count pools created by
  unrelated code in the same internal session.
- Existing generated-program architecture, uncatchable failures, and the
  inability to free pools remain architectural limits rather than hidden
  cleanup promises.
