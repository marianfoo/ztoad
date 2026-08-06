# BASE-RUN-001 implementation and validation plan

_Status: implemented and validated; pull request pending · branch: `codex/fix-base-run-001`_

## Goal and root cause

Make ZTOAD reach a usable query editor in A4H WebGUI without creating a new ST22 dump. The original failure is the default `ABAP` source type passed implicitly to `CL_GUI_ABAPEDIT`; its constructor publishes lexer data through `DP_PUBLISH_URL`, which raises an uncaught `DATA_SOURCE_ERROR`. A live spike additionally proved that the underlying source-editor control has no valid WebGUI frontend handle even when lexer publication is skipped. Full evidence is in [the root-cause report](../research/2026-08-06-base-run-001-webgui-editor-root-cause.md).

## Test-first change

1. Add a pure `LCL_EDITOR_CONFIGURATION` policy with an injected `WEBGUI` flag.
2. First implement the legacy behavior (`ABAP` for every GUI) and add two harmless, short tests:
   - WebGUI expects `TEXT` so the new regression test is red on the original behavior.
   - non-WebGUI expects `ABAP` so desktop behavior is characterized.
3. Deploy that exact red candidate to A4H, activate it, and record that only the focused WebGUI test fails for the intended reason.
4. Spike the smallest plausible fallback, validate it in the live browser, and reject it if it only moves the dump.
5. Introduce a narrow adapter that uses `CL_GUI_TEXTEDIT` in WebGUI and `CL_GUI_ABAPEDIT` elsewhere.
6. Keep the full suite green while mapping only the common operations used by ZTOAD.

## Compatibility and design review

- The change uses syntax and released language features available on SAP_BASIS 750.
- It does not change serialized dynpros, DDIC objects, authorization behavior, query parsing, generated SQL, or persistence.
- The pure policy separates the environment decision from Control Framework construction and is readable without frontend test infrastructure.
- The adapter encapsulates the unavoidable control difference instead of spreading WebGUI conditionals through application code.
- Windows/Java GUI retains the ABAP editor, F1 help, completion, quick info, insert-pattern events, and drag/drop.
- WebGUI uses its supported plain text editor and intentionally omits source-editor-only enhancements.
- `CL_GUI_CONTROL=>WWW_ACTIVE` is the release-local standard signal used throughout SAP's own `CL_GUI_FRONTEND_SERVICES` implementation for SAP GUI for HTML.
- The classic Control Framework remains an on-premise Level-B dependency. This fix removes one unsupported runtime assumption but does not claim ABAP Cloud compatibility.

## Validation matrix

### Local

- `npm ci`
- `npm test`
- `npm run lint:quality` and compare total/per-rule counts; do not add unexplained debt
- `git diff --check`
- review source and serializer diff; only report source and documentation should change
- security review: no SQL, authorization, persistence, or credential boundary changes

### NPL SAP_BASIS 750

- Use ARC-1/ADT only; do not use FLP, WebGUI, SAP GUI, or browser automation.
- If the real transparent table `ZTOAD` is present: deploy the exact report source, activate, run syntax, all ABAP Unit tests, and ATC.
- If the table remains absent: record the exact ADT transparent-table prerequisite as a blocked gate. Do not replace it with a structure and do not report a pass.
- UI smoke and ST22 are not applicable on NPL by maintainer direction.

### A4H SAP_BASIS 758

- Record active/inactive state and pre-test ST22 timestamp.
- Deploy the exact candidate source through ARC-1, activate, run syntax and all ABAP Unit tests.
- Run the recorded ATC variants and distinguish incomplete prerequisite runs from passes.
- Launch ZTOAD through the supported HTTPS WebGUI/FLP path.
- Confirm the editor renders, enter the sanitized read-only query `SELECT SINGLE mandt FROM t000`, and verify the expected result path.
- Re-read ST22 and require no new ZTOAD-related dump.

## Evidence recorded before the pull request

- Red candidate on A4H: 18 passed, only the focused WebGUI policy test failed.
- Rejected SQL-source-type spike: all 19 Unit tests passed, but live WebGUI produced `RAISE_EXCEPTION` in `CL_GUI_SOURCEEDIT` at `2026-08-06T09:30:59Z`; the candidate was not accepted.
- Final adapter: `npm ci`, `npm test`, and `git diff --check` pass.
- Diagnostic full-rule inventory: 1,878 findings versus 1,857 on `master`; 19 additions expose a conflict between default parameter-prefix and no-prefix rules, and 2 classic-exception diagnostics preserve the legacy control-error/`sy-subrc` contract.
- A4H exact active source: no inactive divergence, 0 syntax errors, the same 4 known warnings, and 19/19 Unit tests green.
- A4H ATC: 768 cloud-readiness findings (463 P1, 305 P2); S/4HANA-readiness returned no rows but remains prerequisite-incomplete.
- Fresh WebGUI launch after activation: editor rendered and accepted the read-only query; no new ST22 dump.
- Result execution could not be tested because A4H lacks installed GUI status `STATUS010`, an independent `BASE-BUG-007` prerequisite despite its presence in repository XML.
- NPL: ADT-only connection/lifecycle usable; exact ZTOAD gate blocked by absent transparent table and unavailable 7.50 ADT table-create endpoint.

## Rollback

Restore the original report source from `master` through ARC-1 and reactivate. No database or structural-object rollback is required. If the WebGUI editor renders but loses an essential interaction, revert rather than broadening the same PR into an editor rewrite.

## Final review and PR

After all available gates, review the complete diff and evidence, update `BASE-RUN-001`, commit with a Conventional Commit subject, push, open a PR, and wait for required CI. After its first green run, audit the workflow and CI, apply useful documentation/process improvements in the same PR, move this plan to `docs/plans/finished/`, push, and wait for green again. Do not merge without maintainer direction, especially while the 7.50 ZTOAD gate is blocked.
