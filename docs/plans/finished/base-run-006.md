# BASE-RUN-006 — isolate WebGUI from desktop-only Control Framework operations

_Date: 2026-08-07 · branch: `codex/fix-base-run-006`_

## Goal

Make a fresh A4H WebGUI session execute a sanitized read-only query and display its ALV result without a Control Framework dump, while preserving the complete SAP GUI desktop experience and the SAP_BASIS 750 compatibility floor.

## Proven root cause and scope

The live spike matrix proves multiple independent incompatibilities in ZTOAD's desktop-style WebGUI queue: initial R3-table editor population, selection/cursor behavior, repository/DDIC tree rebuilds, splitter state changes, and history refresh. SAP's standard `SAPTEXTEDIT_TEST_2` transfer succeeds, so this is not a missing system-wide TextEdit/ITS capability.

The smallest coherent fix is an explicit WebGUI core capability profile: initially empty stream-read TextEdit, deterministic last-statement selection, and ALV, without desktop-only workspace conveniences. It does not change SQL parsing, authorization, generated source, row limits, or DML defaults.

## Reviewed implementation plan

1. **Research and sanitized reproduction — complete.** Record the baseline dump, SAP documentation, standard SAP diagnostic, phase-isolation matrix, working core spike, and ST22 boundary in the research note.
2. **RED policy regression.** Extend the existing pure editor configuration with a frontend capability structure. First encode the legacy all-desktop behavior and add WebGUI expectations for core layout, stream input, no initial population, no selection, no splitter changes, and no history/tree refresh. Replay Unit tests against unchanged production paths and record the focused failure.
3. **Plan review — complete before production edit.** Verify 7.50 syntax, Clean ABAP naming, classic on-premise Clean Core limits, command exposure, security invariants, live gates, rollback, and the explicit loss of WebGUI convenience features.
4. **Smallest green implementation.** Make the capability policy return the proven profile and route only the relevant boundaries through it: two-pane initialization, empty TextEdit, stream read, deterministic last-statement selection, no desktop trees/history/sizing/focus, and WebGUI command exclusions. Keep desktop behavior on its current paths.
5. **Local verification.** Run `npm ci`, `npm test`, `npm run lint:quality`, `git diff --check`, focused source-contract review, authorization/security review, and a complete diff review. No permanently failing or skipped test is allowed.
6. **Freeze exact candidate.** Commit before live validation and record commit plus local source SHA-256. Any later source change invalidates live syntax, Unit, ATC, smoke, and object-state evidence.
7. **Live gates.** NPL first if its real table prerequisite becomes available; otherwise record the existing prerequisite block. On A4H require explicit activation, active/inactive equality, no inactive ZTOAD child part, active syntax, all ABAP Unit tests, complete ATC result/prerequisite accounting, a fresh read-only WebGUI result, and no post-candidate ST22 delta.
8. **Restore shared target.** After evidence, deploy and activate intended `master` source unless the maintainer explicitly reserves the exact candidate for the next operation. Keep the native-abapGit repository on `master` throughout this source-only change.
9. **Final review and PR.** Update the finding register/system dossier, commit with a Conventional Commit subject, push, open the PR, and wait for required CI.
10. **Post-green workflow audit.** Review the plan, red/green evidence, exact-candidate discipline, ARC-1 friction, GitHub output, and CI. Put clearly useful process improvements in the same PR, move this plan to `docs/plans/finished/`, and wait for CI again.

## Plan review

- **Compatibility:** use only syntax and APIs available on SAP_BASIS 750. `CL_GUI_TEXTEDIT`, `CL_GUI_ALV_GRID`, splitter containers, classic structures, and boolean policy values already exist at the floor.
- **Clean ABAP:** one named capability profile is easier to review than repeated unstructured `WWW_ACTIVE` checks. Keep the legacy report formatting stable outside touched blocks.
- **Clean Core:** this remains classic Level-B/on-premise GUI code. The fix reduces accidental dependency on frontend-internal behavior but does not claim ABAP Cloud compatibility.
- **Security:** deterministic last-statement selection replaces unavailable frontend selection/cursor state; it does not change validation or authorization. Dynamic source authorization, generated-fragment validation, row limits, disabled Native SQL, and DML confirmation remain intact. WebGUI history is not persisted automatically, avoiding an unexpected database write.
- **UX:** WebGUI starts empty and offers the proven core commands. Saved-query trees, DDIC assistance, multi-tab layout, generated-code editor, options, import/export, and frontend downloads remain desktop features until separately proven. This limitation must be documented rather than represented as full feature parity.
- **Testing:** ABAP Unit can prove policy and parser behavior but cannot prove browser controls. The fresh exact-candidate WebGUI run plus ST22 delta remains a non-waivable integration gate.
- **Rollback:** revert the source commit, deploy the reviewed previous `master` report source directly, explicitly activate it, and recheck object state. No structural object or persistent test data is introduced.

## Evidence log

- Original A4H RED: 2026-08-07 04:31:22 UTC `MESSAGE_TYPE_X`, `SAPLOLEA`/`AC_SYSTEM_FLUSH`, CNDP 006, `SY-SUBRC=4`, `SY-UCOMM=EXECUTE`.
- Standard system control: `SAPTEXTEDIT_TEST_2` successfully transferred edited text to its ABAP table with no new dump.
- Spike GREEN: two-pane empty TextEdit plus ALV; `GET_TEXT_AS_STREAM` read browser input; `SELECT SINGLE mandt FROM t000` returned client `000`, count `1`; no ST22 entry after 06:27:30 UTC.
- Target restoration before TDD: A4H was returned to exact `master` source, explicitly activated, active/inactive SHA-256 `21ef81d0b925bca71182822a0e9650cb80b32c6e3fd3ae4d1d73576011cb74b7`, with no inactive ZTOAD entry.
- TDD RED: source SHA-256 `95b6f780a86263a24a6016a41d978458e6a2242d18b5c05650ce02b8c617a405` was explicitly activated on A4H; `LTCL_EDITOR_CONFIGURATION->LIMITS_WEBGUI_CAPABILITIES` failed because the legacy policy still queued the desktop workspace, while the other 56 tests passed.
- Local GREEN: `npm ci`, the pinned zero-finding abaplint gate, repository/install contracts, and `git diff --check` passed. After the ATC-driven adapter refactor, the diagnostic quality inventory is 2,109 findings across 61 legacy rules versus 2,051/61 on exact master. The +58 preference/naming/typing findings expose the named capability structure, explicit guards, and four policy tests; no parser, security, SQL, obsolete-statement, dangerous-statement, or return-code rule increased. The inventory remains non-blocking.
- Candidate review refinement: first frozen commit `ad37d7b` repeated direct frontend detection at each guard and raised Cloud ATC from master's 668 to 695. Centralizing that detection reduced the final complete run to 682 and made one adapter the runtime boundary. All affected evidence was discarded and rerun.
- Exact candidate: commit `31eca9936202b63874ba089e3744fe9971dfa0e4`; local source SHA-256 `4b4823a5db169697696d71edf42b432ca66db0d8585c36066a3bd3817f61a2e5`.
- A4H activation/state: explicit activation succeeded; active syntax had 0 errors and the 2 pre-existing POSIX warnings; active/inactive source was equal at server SHA-256 `138d7cf38e68649abb7d714093afc809a27f7a26ca98b511d15dec4ef68d9e36`; the global inactive inventory contained no ZTOAD object or child part.
- A4H Unit/ATC: all 57 tests passed. Complete `ABAP_CLOUD_READINESS` returned 682 findings (474 P1, 208 P2), +14 versus master's 668. `S4HANA_READINESS_2023` returned zero rows but no prerequisite/completeness evidence and is therefore recorded as incomplete, not passed.
- Exact-candidate browser GREEN: a fresh standalone WebGUI session exposed only the tested commands, started empty, accepted `SELECT SINGLE spras FROM t002.` followed by `SELECT SINGLE mandt FROM t000.`, deterministically executed the last statement, displayed grid title `SELECT SINGLE mandt FROM t000`, row `000 / 1`, and the one-entry success message. F3 returned cleanly to S000.
- ST22 delta: no dump exists after the pre-smoke marker at 2026-08-07 06:26:10 UTC.
- NPL: exact ZTOAD syntax/Unit/ATC remains blocked by the documented missing transparent-table prerequisite; no UI gate was attempted.
- Shared-target restoration: `origin/master` commit `2360fe4` source was redeployed and explicitly activated. Active/inactive server SHA-256 is again `21ef81d0b925bca71182822a0e9650cb80b32c6e3fd3ae4d1d73576011cb74b7`, with no inactive ZTOAD object.

## References

- [Root-cause research](../../research/2026-08-07-base-run-006-webgui-execute-flush.md)
- [Development playbook](../../development.md)
- [Test strategy](../../test-strategy.md)

## Post-green process audit

- PR #24 first head `8ac8840` passed Quality run `31155861891` and external abaplint. CI checked the GitHub merge ref, installed pinned dependencies with `npm ci`, and ran the same complete `npm test` contract used locally; no workflow gap or CI change was justified.
- Exact-candidate discipline worked: the initial ATC review exposed repeated frontend API boundaries, the source was refined, and every affected SAP/runtime gate was rerun before evidence was accepted. Documentation-only evidence commits did not invalidate the frozen source hash.
- The shared native-abapGit repository remained on full ref `refs/heads/master`, the source-only candidate was deployed directly, and A4H was restored to exact master afterward. The ARC-1 audit now distinguishes installed system capability from client/schema/credential/postcondition gaps.
- ARC-1 ignored the requested ST22 time filter, so the workflow now requires an explicit before-marker plus client-side dump-set comparison. Browser guidance now scopes editor actions because ALV adds other textbox roles after execution. These changes are in `AGENTS.md`, the test strategy, and the PR template.
- No production source, serialized SAP object, CI workflow, dependency, release file, or live-system state changed during this audit. The plan is complete and moved to `docs/plans/finished/`; a second green PR run is required before handoff.
