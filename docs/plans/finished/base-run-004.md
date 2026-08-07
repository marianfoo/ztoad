# BASE-RUN-004 — enforce bounded SELECT results

_Date: 2026-08-07 · branch: `codex/base-run-004`_

## Goal

Remove the `UP TO 0 ROWS` unlimited-result bypass, centralize a positive row-
limit policy for every generated SELECT representation, preserve valid bounded
queries, and keep the SAP_BASIS 750 compatibility floor.

## Proven root cause and red evidence

Official SAP documentation defines a runtime value of zero as up to
2,147,483,647 rows. ZTOAD removes the user's clause and represents zero as an
initial `fw_rows`; legacy SELECT, strict SELECT, and set-cursor generation then
all omit their cap. A saved default of zero reaches the same sentinel.

Red commit `ccea89741a3317de361c54b081c657def4ee9899` is syntax-valid on
NPL and runs 113 tests: 112 pass and only the focused zero-limit assertion
fails. The reproduction performs no SELECT. Full analysis is in the linked
research note.

## Reviewed implementation plan

1. **Baseline and research — complete.** Align both systems to merged master,
   verify the 113-test baseline and exact object state, trace parser and all
   generator representations, and confirm zero semantics through official SAP
   documentation.
2. **Focused red test — complete.** Change the existing zero-limit
   characterization into a fail-closed regression and replay it against
   unchanged production behavior on SAP_BASIS 750.
3. **Central policy.** Add one pure local row-limit policy with fallback 100 and
   maximum 10,000. Resolve explicit text before numeric assignment; reject zero,
   invalid, overflow, and above-maximum explicit values. Normalize missing or
   invalid saved defaults to 100 and cap oversized saved defaults at 10,000.
4. **Parser integration.** Recognize the complete top-level row token, pass it
   through the policy before removing the clause, and return `fw_error` for an
   unsafe explicit request. Ensure the parser always supplies a positive value
   to generation for an executable multirow SELECT.
5. **Regression/refactor.** Add pure cases for exact maximum, above maximum,
   invalid/negative/overflow tokens, leading zeros, zero and oversized saved
   defaults, literal lookalikes, and normal positive/default behavior. Replace
   the set-query unlimited test with a fail-closed full-path regression while
   retaining strict, legacy, aggregate, and positive UNION generation tests.
6. **Documentation.** Remove the advertised unlimited mode from embedded help
   and README, document the 1–10,000 policy and safe default recovery, and state
   honestly that a result cap is not a database statement timeout.
7. **Local gates and review.** Run `npm ci`, `npm test`, the diagnostic quality
   profile, `git diff --check`, a complete diff review, and focused checks for
   parser/generator consistency, authorization, generated-fragment validation,
   overflow, aggregate semantics, and both set/non-set representations.
8. **Freeze exact candidate.** Commit source and documentation, record the
   commit and source SHA-256, and invalidate affected live evidence after any
   later `src/` change.
9. **NPL gate first.** Directly deploy the exact candidate, explicitly activate,
   and require active syntax, every ABAP Unit test, complete DEFAULT ATC,
   active/inactive equality, zero inactive ZTOAD child parts, and no new dump.
   NPL UI remains not applicable.
10. **A4H gate.** Repeat activation, syntax, Unit, complete Cloud ATC, object
    state, and inactive-child checks. In a fresh browser session, submit a safe
    `UP TO 0 ROWS` query and prove rejection without a result, then submit a
    small positive-limit read-only query and prove the bound. Compare the full
    ST22 set client-side with the pre-smoke marker.
11. **Restore and PR.** Restore both shared systems to intended merged master,
    verify activation/state/tests, perform the final review, update the finding,
    push, open the PR, and wait for required green CI.
12. **Post-green audit.** Audit plan fidelity, evidence, ARC-1 behavior, PR diff,
    and CI. Add useful durable workflow improvements to the same PR, archive
    this plan under `docs/plans/finished/`, wait for green CI again, then squash
    merge and synchronize local master.

## Execution record

- Steps 1–11 through shared-system restoration are complete for frozen source
  commit `832d057656dc2923e79b87eff5016b718dad42fe`; local source
  SHA-256 is
  `b8d5d7807e42832b105deabe4d55f142ee10408a4f1ef975cf9530d17cf2ebb4`.
  Both candidate deployments reported normalized active/inactive SHA-256
  `1e93f56cd0575ca73a1cc2c5b270ee07436db9839e3412ddd73448a8cc771264`.
- The focused NPL red replay at commit `ccea897` passed 112/113 Unit and
  failed only `LTC_QUERY_PARSER->REJECTS_ZERO_LIMIT`; no SELECT was executed.
- `npm ci`, configured abaplint, repository and installation contracts,
  `git diff --check`, both server-side dry syntax checks, and the complete diff
  review are green. The diagnostic quality inventory is 2,524 findings across
  62 rules and remains outside the merge gate.
- NPL is green at 120/120 Unit with clean active syntax, equal source state,
  zero inactive ZTOAD parts, and complete DEFAULT ATC unchanged at 85 findings
  (P1 3, P2 4, P3 78). Its four-dump result set and latest marker remained
  unchanged across the candidate checks.
- A4H is green at 120/120 Unit with the known seven POSIX warnings, equal
  source state, and zero inactive ZTOAD parts. Complete
  ABAP_CLOUD_READINESS improved from 709 to 706 findings (P1 487, P2 219): a
  stable-signature comparison shows only two fewer restricted-form errors and
  one fewer generic restricted-syntax error, with no new signature.
  `S4HANA_READINESS_2023` again returned zero displayed findings without
  proving its unavailable prerequisites and remains explicitly incomplete.
- A fresh authenticated Chrome/WebGUI session entered both queries with
  editor-scoped click, real typing, and blur. The zero-limit query
  `SELECT mandt FROM t000 UP TO 0 ROWS` stopped with `Cannot parse the query`
  and an empty grid. A following
  `SELECT tabname FROM dd02l UP TO 2 ROWS` returned exactly two rows and the
  success message reported two entries. The complete 49-ID ST22 set retained
  its latest `2026-08-07T06:26:10Z` marker and gained no ID.
- Both shared targets were restored to merged master `ef54657`, explicitly
  activated, and verified at 113/113 Unit, expected syntax, equal active and
  inactive SHA-256
  `736c93b341c8a14cd40f88522b6b542fa14b82bceaea5a34b0bedcfdab2699b8`,
  and zero inactive ZTOAD part.
- Draft PR #33 opened from the recorded candidate and its first Quality run
  `31196346909` passed `npm ci`, configured abaplint with zero findings, the
  repository contract, and the installation contract. The external abaplint
  observation check was neutral by design; both required checks passed.
- The post-green audit reconciled all six changed files with the PR diff,
  reviewed the complete CI log, found no review comments or unresolved threads,
  and confirmed the PR was cleanly mergeable. It found one stale security-
  checklist reference to a documented unlimited override; the checklist now
  states the bounded invariant instead.
- The workflow now explicitly requires separate validation of explicit input
  and persisted/default configuration whenever zero or initial values could
  act as an omit-policy sentinel. This plan is archived after that durable
  improvement; the second green run and merge are recorded on the PR so they do
  not require an evidence-only commit.

## Plan review

- **Compatibility:** no syntax or API newer than SAP_BASIS 750 is planned.
- **Clean ABAP/readability:** one named pure class owns fallback, ceiling,
  conversion, and invalid-state decisions; the parser remains an adapter.
- **Clean Core:** this remains a classic on-premise report. The change adds no
  unreleased dependency and makes no false ABAP Cloud claim.
- **Security and safety:** unsafe values fail before generated source or a
  database request. Authorization, source scanning, fragment validation,
  runtime containment, DML policy, and subroutine-pool budgeting remain intact.
- **Representation boundary:** tests must prove the policy at parsing and the
  final strict/legacy/set representations; an initial value must never regain
  its old "omit the cap" meaning downstream.
- **Testing:** permanent tests are harmless and data-in/data-out. Live smoke is
  read-only and deliberately small; no load test materializes a large result.
- **Functional tradeoff:** unlimited results are intentionally removed. Users
  must paginate/refine a query rather than risk dialog-session memory.
- **Rollback:** revert the candidate, redeploy and explicitly activate reviewed
  master on both targets, then rerun syntax, Unit, state, and inactive-child
  checks. No structural object or persistent data is introduced.

## References

- [Root-cause research](../../research/2026-08-07-base-run-004-row-limit-policy.md)
- [Development playbook](../../development.md)
- [Test strategy](../../test-strategy.md)
