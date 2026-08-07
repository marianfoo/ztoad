# BASE-RUN-003 — bound temporary subroutine-pool use

_Date: 2026-08-07 · branch: `codex/base-run-003`_

## Goal

Prevent repeated ZTOAD requests from reaching SAP's hard 36-pool internal-
session limit. Count only successfully generated executable pools, avoid an
allocation when DML is cancelled, preserve source display and successful query
behavior, and keep the SAP_BASIS 750 compatibility floor.

## Proven root cause and red evidence

SAP documents a maximum of 36 temporary subroutine pools per internal session,
no explicit deletion, and a saved short dump plus database rollback on a
generation exception even when `sy-subrc = 8`. ZTOAD currently admits 1,000
runs. The value was originally 36 and was raised in version 4.0.3 without a
change to the generated-pool lifecycle.

Red commit `9b98a2d904825136e55a86d55ca1e1ce31cd3ecd` is syntax-valid on
NPL and runs 110 tests: 109 pass and the focused budget assertion fails because
1,000 exceeds 36. The reproduction consumes no pool and creates no intentional
dump. Full analysis is in the linked research note.

## Reviewed implementation plan

1. **Research and baseline — complete.** Trace both generator sinks and their
   callers, confirm SAP's lifecycle contract through official documentation,
   inspect the historical limit change, align both live systems to current
   `master`, and record clean 109/109 baselines.
2. **Focused red test — complete.** Add one harmless budget assertion and replay
   it on SAP_BASIS 750 against unchanged production behavior.
3. **Smallest green policy.** Replace the 1,000-run global constant with a small
   local OO budget policy exposing SAP's limit (36), an explicit reserve (6),
   and ZTOAD's maximum (30). Admit real generation only below 30 and register a
   charge only after a non-display generation returns a program handle.
4. **Correct orchestration.** Enforce admission inside both actual generator
   sinks, remove the duplicated outer counter gates/increments, and move the DML
   confirmation before generation. Preserve parsing, authorization, input
   validation, generated-source validation, execution containment, and all
   read-only result behavior.
5. **Regression/refactor.** Replace the red assertion with pure boundary tests:
   repeatedly request more than SAP's maximum without allocating real pools,
   prove the count stops at 30, prove the six-slot reserve, and prove display or
   failed generation does not charge. Retain existing successful generator
   tests; do not add a 36-pool live stress test because the resource cannot be
   cleaned up inside the session.
6. **Local gates and review.** Run `npm ci`, `npm test`, the diagnostic quality
   profile, `git diff --check`, a complete diff review, and focused checks for
   authorization, DML confirmation order, counter bypass, source-display
   behavior, and both `GENERATE SUBROUTINE POOL` sinks.
7. **Freeze exact candidate.** Commit production and test source, record its
   commit and local SHA-256, and invalidate live evidence if `src/` changes.
8. **NPL gate first.** Directly deploy the exact candidate, explicitly activate,
   require active syntax, every ABAP Unit test, complete `DEFAULT` ATC
   accounting, active/inactive source equality, zero inactive ZTOAD child parts,
   and no new dump from the focused tests. NPL UI remains not applicable.
9. **A4H gate.** Repeat exact activation, syntax, Unit, ATC, state, and inactive-
   child checks. In a fresh supported browser session, execute read-only
   queries until the ZTOAD budget boundary is exercised only if this can be done
   without approaching SAP's hard limit; otherwise use the pure boundary test
   plus one normal read-only smoke. Compare the full ST22 result set client-side
   against a pre-smoke marker.
10. **Restore shared targets.** Redeploy and explicitly activate intended
    `master` on both systems, then verify syntax, the 109-test baseline, source
    equality, and zero inactive ZTOAD parts. Keep native abapGit on
    `refs/heads/master`.
11. **Final review and PR.** Update the finding evidence, commit with a
    Conventional Commit subject, push, open the PR, and wait for required CI.
12. **Post-green workflow audit.** Review plan fidelity, evidence, ARC-1/tooling,
    GitHub and CI. Add only durable process improvements to the same PR, move
    this plan to `docs/plans/finished/`, and wait for green CI again before
    squash merge.

## Plan review

- **Compatibility:** no syntax or API newer than SAP_BASIS 750 is required.
- **Clean ABAP/readability:** one named policy owns all numbers and accounting;
  the procedural generators remain small adapters around the legacy report.
- **Clean Core:** the generated-pool architecture remains classic Level D-style
  on-premise code. This finding reduces runtime risk without claiming a Clean
  Core conversion.
- **Security and safety:** admission occurs before the sink; the implementation
  never relies on the documented generation-error path because that path can
  dump and roll back. Parser, source authorization, Native SQL retirement,
  generated-fragment validation, and DML authorization stay unchanged.
- **Representation boundary:** tests model logical generation outcomes rather
  than allocating undeletable live pools. Runtime review must still prove both
  physical generator statements consult and charge the same policy.
- **Testing:** all new permanent tests are harmless, short, data-in/data-out,
  and make no database changes. Browser smoke is read-only and NPL stays
  ADT-only.
- **Functional tradeoff:** the interactive report stops after 30 generated
  executions in one session and asks the user to restart. That is intentional,
  explicit headroom below SAP's absolute limit.
- **Rollback:** revert the source candidate, redeploy and explicitly activate
  reviewed `master` on both systems, then rerun syntax, Unit, state, and inactive-
  child checks. No structural object or persistent data is introduced.

## References

- [Root-cause research](../research/2026-08-07-base-run-003-subroutine-pool-budget.md)
- [Development playbook](../development.md)
- [Test strategy](../test-strategy.md)
