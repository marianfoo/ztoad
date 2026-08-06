# BASE-BUG-006 plan: serialized ZTOAD transaction

_Date: 2026-08-06 · branch: `codex/fix-base-bug-006` · issue: [#2](https://github.com/marianfoo/ztoad/issues/2)_

## Goal

Ship native-abapGit metadata for a stable `ZTOAD` report transaction, prove direct A4H launch through FLP and standalone WebGUI, and make omission or semantic drift of that transaction fail the normal local/CI test command.

## Scope and invariants

- Stay on a short-lived branch from refreshed `master`.
- Preserve the executable report's `START-OF-SELECTION` entry path by using a report transaction for program `ZTOAD` and generated selection screen `1000`.
- Support SAP GUI for HTML and Windows; make no untested Java-GUI claim.
- Produce `src/ztoad.tran.xml` only through active A4H transaction maintenance plus native abapGit serialization.
- Do not change production ABAP logic for this structural bug.
- Do not use FLP, WebGUI, SAP GUI, or browser automation on NPL. NPL checks are ARC-1/ADT-only.
- Keep `BASE-BUG-007` separate: missing installed `STATUS010` may block query dispatch but must not be misclassified as a transaction-launch failure.

## TDD and implementation sequence

1. **Research/root cause:** confirm issue #2, absent repository/live transaction, report-vs-dialog semantics, abapGit `TRAN` support, authorization effects, and dual-system constraints. Record the result in the linked research note.
2. **Red repository contract:** add a dependency-free Node test that requires the canonical `TRAN ZTOAD` file and its launcher semantics. Wire it into `npm test`, run it before the object exists, and record the expected failure.
3. **Plan review:** verify the test checks behavior-defining metadata without duplicating the entire serializer format; verify structural creation, clean-core, security, compatibility, rollback, and installation drift are addressed.
4. **A4H creation:** use SE93 to create report transaction `ZTOAD` for program `ZTOAD`, package `ZTOAD`, short text `ZTOAD SQL query tool`, HTML/Windows support, and the existing modifiable workbench request.
5. **Native serialization:** use native abapGit to stage only `TRAN ZTOAD` on this feature branch, inspect the XML, commit/push it, and verify a subsequent stage/refresh is clean. Do not stage unrelated A4H drift.
6. **Local green/refactor:** make the repository contract reflect the native result, then run `npm ci`, `npm test`, and `npm run lint:quality`. Review the diff for hand-authored XML, credentials, generated noise, authorization changes, and new strict-lint debt.
7. **Live validation:** use ARC-1/ADT on A4H for transaction metadata, active/inactive state, syntax, ABAP Unit, and ATC. Record ST22 before and after fresh direct FLP and standalone WebGUI launches. Prove the transaction resolves and reaches ZTOAD; preserve `BASE-BUG-007` as the independent dispatch blocker if still present.
8. **NPL validation:** use only the configured ARC-1/ADT connection. Read `TRAN ZTOAD` and run every applicable lifecycle gate. Record native-serialization/install limitations as blocked, never as passed or silently skipped.
9. **Implementation review:** inspect the final diff and evidence against the research decision, Clean ABAP/clean-core guidance, compatibility, security, docs, issue register, and release note.
10. **PR and first CI:** open a draft PR with red/green and live-system evidence; wait for every required check to finish green.
11. **Post-green process audit:** review the complete workflow and GitHub results. Put any clearly beneficial documentation, test-contract, PR-template, or CI improvement into the same PR. If a workflow changes, treat it as a new CI cycle.
12. **Final CI:** push the audit changes and wait until the PR is green again. Move this plan to `docs/plans/finished/` only when all achievable gates and the audit are complete.

## Plan review

The plan is intentionally structural:

- A local file-existence/semantic contract supplies the missing red-green signal; ABAP Unit is not suitable because the transaction is an external repository object, not report logic.
- The contract will check only the serializer identity, transaction/program/screen/type, English description, and required GUI support. It will not snapshot the full XML or system-specific fields.
- The native serializer remains authoritative. If A4H emits different but valid metadata, review the semantic decision and update the test from the serialized result rather than editing XML to satisfy a guessed shape.
- Direct launch and the ADT transaction read test different risks: repository portability versus runtime routing. Both are required on A4H.
- NPL's ADT-only boundary makes native `TRAN` creation/round-trip unavailable; documenting that exact missing gate is more accurate than using a forbidden UI workaround.
- Rollback is a normal revert plus native abapGit pull/uninstall of `TRAN ZTOAD`; no database data is created or migrated.

## Evidence log

- Red baseline: `npm test` on 2026-08-06 passed configured abaplint with 0 issues, then failed in `scripts/repository-contract.mjs` with `Missing native-abapGit transaction object: src/ztoad.tran.xml`.
- Local green: pending.
- A4H ADT/live/native-abapGit: pending.
- NPL ARC-1/ADT-only: pending.
- First PR CI: pending.
- Post-green process audit and final CI: pending.
