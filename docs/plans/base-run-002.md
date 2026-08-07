# BASE-RUN-002 — isolate generated-query failures

_Date: 2026-08-07 · branch: `codex/base-run-002`_

## Goal

Give generated SELECT and DML programs one stable, sanitized failure contract: expected catchable execution failures return to ZTOAD without an ST22 dump, partial results, a success message, or query-detail leakage. Preserve successful behavior and the SAP_BASIS 750 floor.

## Proven root cause and red evidence

The generator displays raw `SYNTAX-CHECK` text, and `QUERY_PROCESS` directly executes the temporary pool with no exception boundary. Red commit `1c1e748c691a44f95302b11977fa5a497abbeeee` is syntax-clean on NPL and has equal active/inactive source, but passes only 106/108 tests: one deterministic generated arithmetic exception escapes and one synthetic compiler detail is returned unchanged. The NPL ST22 list did not change. A disposable NPL spike proved that `CATCH CX_ROOT` at the external-PERFORM boundary contains the runtime failure on the 7.50 floor.

SAP separately states that a `GENERATE SUBROUTINE POOL` generation error can still create a dump even when the statement returns `sy-subrc = 8`. This plan does not overclaim protection from uncatchable failures or the finite pool limit tracked by `BASE-RUN-003`.

## Reviewed implementation plan

1. **Research and reproduction — complete.** Trace both generator sinks and the runtime call, check SAP exception/generation contracts, establish clean 106/106 target baselines, and record the two-test NPL red replay.
2. **Focused red tests — complete.** Add a harmless generated routine that raises a deterministic catchable arithmetic exception, plus a synthetic technical-detail sanitizer regression. Preserve original behavior while introducing only the narrow execution and formatting seams needed to test it.
3. **Smallest green implementation.** Catch `CX_ROOT` only around the external generated `PERFORM`; never inspect its text. Clear result, runtime, and count on failure. Map compiler/generation/runtime details to the existing generic text and use a non-terminating error-style message in `QUERY_PROCESS`. Check `sy-subrc` after both pool-generation statements and clear the executable handle on failure.
4. **Regression/refactor.** Add the success-path assertion through the new executor and verify failure leaves all outputs initial. Keep the procedural adapter because ABAP Objects forbids this external-PERFORM variant; do not expand the refactor into parser, GUI, row-limit, DML, or pool-lifecycle work.
5. **Local gates.** Run `npm ci`, `npm test`, `npm run lint:quality`, `git diff --check`, reconcile every changed file, review the full diff, and perform a focused security review for information leakage, exception scope, result/history suppression, and unchanged authorization/input validation.
6. **Freeze exact candidate.** Commit the production/test candidate and record its commit plus local source SHA-256 before live validation. Any later `src/` change invalidates all affected live evidence.
7. **NPL gate first.** Directly deploy the exact source with the pre-write lint mismatch bypassed only after the pinned repository gate passes. Explicitly activate; require active/inactive equality, zero inactive ZTOAD child parts, active syntax, all 109 Unit tests, complete `DEFAULT` ATC accounting, and no new dump from the focused expected-failure test.
8. **A4H gate.** Repeat exact activation, state, syntax, all Unit tests, and complete/incomplete ATC accounting. Snapshot the full recent ST22 set, then use a fresh A4H browser session for one sanitized read-only runtime-failure query and one ordinary read-only success query. Require the generic message, no query detail, a valid normal result, and no new dump.
9. **Restore shared targets.** Redeploy and explicitly activate intended `master` on NPL and A4H after evidence, then verify syntax, the 106-test master baseline, active/inactive equality, and no inactive ZTOAD child part. Native abapGit remains on `refs/heads/master` throughout this source-only work.
10. **Final review and PR.** Update the finding register and evidence, commit with a Conventional Commit subject, push, open the PR, and wait for required CI.
11. **Post-green workflow audit.** Review plan fidelity, red/green evidence, exact-candidate discipline, ARC-1 behavior, GitHub output, and CI. Apply only clearly useful process/documentation improvements in the same PR, move this plan to `docs/plans/finished/`, and wait for CI again before squash merge.

## Plan review

- **Compatibility:** `TRY`, `CATCH CX_ROOT`, boolean result flags, and the existing text symbol are supported on SAP_BASIS 750. The external `PERFORM` remains in a FORM because SAP documents this variant as forbidden in classes.
- **Clean ABAP/readability:** one named formatter and one execution adapter make the trust boundary explicit. Broad exception handling is limited to exactly the user-derived generated routine and does not hide failures elsewhere in ZTOAD.
- **Clean Core:** temporary generated programs and external subroutines remain classic on-premise architecture, not ABAP Cloud. This change reduces leakage/dumps but makes no Clean Core level improvement claim.
- **Security:** never call `GET_TEXT` on the exception or display compiler line/word/query data during execution. Parser validation, every-source authorization, disabled Native SQL, generated-fragment validation, DML confirmation, and row-limit behavior remain unchanged.
- **Representation boundary:** tests operate on the actual temporary program invocation. Compiler details are treated as tainted even after `SYNTAX-CHECK`; generated-source display remains an explicit same-user diagnostic action, not an automatic error response.
- **Testing:** the arithmetic fixture is deterministic and changes no database data. The live runtime-failure query must be read-only and sanitized. No NPL UI automation is permitted.
- **Known limit:** uncatchable runtime errors and `GENERATE SUBROUTINE POOL` generation errors can still dump. `BASE-RUN-003` must prevent the 36-pool exhaustion path rather than relying on post-error handling.
- **Rollback:** revert the source commit, directly deploy and explicitly activate reviewed `master` on each system, then rerun syntax, Unit, state, and inactive-part checks. No structural object or persistent data is introduced.

## References

- [Root-cause research](../research/2026-08-07-base-run-002-query-error-contract.md)
- [Development playbook](../development.md)
- [Test strategy](../test-strategy.md)
