# BASE-RUN-006: WebGUI Control Framework execution boundary

_Observed 2026-08-07 on A4H client 001, SAP_BASIS/SAP_UI 758 SP02, after the complete `BASE-BUG-007` native-abapGit activation. All queries and editor contents used below are sanitized and read-only._

## Reproduction and baseline

1. Start a fresh WebGUI transaction `ZTOAD`.
2. Enter `SELECT SINGLE mandt FROM t000`.
3. Choose **Execute**.

The original program left the application and created a `MESSAGE_TYPE_X` dump at 2026-08-07 04:31:22 UTC in `SAPLOLEA`, function `AC_SYSTEM_FLUSH`, with CNDP 006, screen 0010, `STATUS010`, and `SY-UCOMM = EXECUTE`. `SY-SUBRC = 4` identified a queued property-get failure. This proves that the restored GUI status dispatches correctly and that the failure is a separate Control Framework runtime defect.

## Official SAP contract

SAP documents `SET_TEXT_AS_STREAM`, `GET_TEXT_AS_STREAM`, `SET_TEXT_AS_R3TABLE`, and `GET_TEXT_AS_R3TABLE` as synchronous whole-text transfers. It also documents the TextEdit attribute cache and the need to flush before relying on cached state. The ALV method matrix marks `SET_TABLE_FOR_FIRST_DISPLAY` as usable in SAP GUI for HTML. These contracts support a TextEdit-plus-ALV WebGUI mode, but they do not make every desktop tree, selection, focus, or splitter operation portable.

- [Special Considerations for the SAP Textedit](https://help.sap.com/docs/ABAP_PLATFORM_NEW/70396d7dec4c4f19b9ca3b2e47559d12/4d7c386419a00f88e10000000a42189b.html)
- [Setting and Getting Text](https://help.sap.com/docs/ABAP_PLATFORM_NEW/70396d7dec4c4f19b9ca3b2e47559d12/4d7c35f419a00f88e10000000a42189b.html)
- [Methods of Class CL_GUI_ALV_GRID](https://help.sap.com/docs/ABAP_PLATFORM_NEW/70396d7dec4c4f19b9ca3b2e47559d12/22a3f5ecd2fe11d2b467006094192fe3.html)

## Boundary matrix

The same fresh-session query was replayed while changing one phase at a time. Each spike was syntax-checked, explicitly activated, and discarded after measurement.

| Boundary | Result | Interpretation |
|---|---|---|
| Original desktop-style workspace | `MESSAGE_TYPE_X`, property get | At least one queued control operation is not valid in this WebGUI cycle. |
| Skip only result display | Red | ALV presentation is not the only cause. |
| Hard-code the harmless query; omit DDIC, result, and history work | Green | SQL parsing/generation/execution and screen dispatch are sound. |
| Re-enable DDIC refresh | Red | The dynamic DDIC tree is an independent incompatible boundary. |
| Replace `DELETE_ALL_NODES`, then also omit root expansion | Red | The complete runtime tree rebuild, not one delete call, is unsafe here. |
| Real ALV with splitter reads/writes omitted | Green | `CL_GUI_ALV_GRID->SET_TABLE_FOR_FIRST_DISPLAY` is usable. |
| Re-enable result splitter get/set | Red | Splitter state/reveal operations are an independent incompatible boundary. |
| Re-enable repository/history refresh | Red | The repository tree refresh is another independent incompatible boundary. |
| Editor selected-text/cursor getters | Red | WebGUI cannot use the desktop active-selection algorithm. |
| Full text via `GET_TEXT_AS_R3TABLE` | Red in the combined desktop queue | The table property path is not a safe execution adapter in this workspace. |
| Full text via `GET_TEXT_AS_STREAM`, while desktop initialization remained queued | Red | Changing only the getter cannot repair the poisoned automation queue. |
| SAP standard transaction `SAPTEXTEDIT_TEST_2`, edit plus **Save to R/3 table** | Green, no dump | A4H/ITS has working TextEdit transfer in general; this is not a missing system-wide TextEdit capability. |
| ZTOAD two-pane layout, bare TextEdit construction | Green | The TextEdit control itself and the main splitter are valid. |
| Add initial `SET_TEXT_AS_R3TABLE` population | Red, `SY-SUBRC = 2` method-call failure | Initial server-to-control text population is the remaining launch failure. |
| Bare TextEdit plus ALV, stream read, no desktop trees/sizing/history | Green | Browser input was read, the query ran, ALV showed client `000`, and the success message reported one row. |

The green core execution completed after 06:27:30 UTC with no later ST22 entry. The exact UI evidence was `SELECT SINGLE mandt FROM t000`, ALV row `000 / 1`, and `Query executed in 0.00 seconds. 1 entries found`.

## Root cause

`BASE-RUN-006` is not one missing flush. ZTOAD treated SAP GUI for HTML as a drop-in replacement for a desktop Control Framework workspace and queued several operations whose execution contracts do not hold in this WebGUI lifecycle:

- initial R3-table population and focus/selection behavior for the query editor;
- runtime rebuilds of the repository and DDIC trees;
- frontend splitter state reads and row-height changes;
- automatic history refresh after execution.

The automatic PBO flush reports whichever incompatible operation reaches the frontend first, which is why later result-path changes alone could not fix the dump. Removing the whole flush would only hide the real boundary and leave an invalid queue.

## Recommended product contract

Keep the complete four-pane, preloaded, multi-tab desktop workspace unchanged. Give WebGUI an explicit core mode:

- a two-pane layout containing an initially empty TextEdit and the ALV result;
- whole-text transfer through `GET_TEXT_AS_STREAM`, followed by deterministic selection of the last complete statement without reading frontend cursor state;
- no selected-statement/cursor semantics;
- no dynamic repository/DDIC tree, automatic history persistence, initial text preload, frontend focus request, or splitter resizing;
- only commands whose controls and frontend services are proven in this mode.

This is a deliberate capability adapter, not silent exception suppression. The missing convenience features should be visible in documentation and may be reintroduced individually only with a focused WebGUI integration test.

## TDD acceptance

1. A pure capability-policy Unit test must fail against the legacy desktop assumptions and turn green with the WebGUI core contract.
2. Desktop policy tests must prove that the existing editor, workspace, selection, preload, splitter, and history behavior is retained.
3. The exact candidate must pass local abaplint/repository tests, SAP syntax, all ABAP Unit tests, ATC comparison, activation/object-state checks, a fresh WebGUI read-only query, and an ST22 delta.
4. NPL remains ADT-only and prerequisite-blocked until its real `ZTOAD` table exists; no browser claim is made there.

## System conclusion

No missing A4H system object or general TextEdit service was found. Native transaction/screen/status installation is complete, and SAP's own TextEdit diagnostic succeeds. The remaining defect is ZTOAD's unscoped desktop-control orchestration. A future SAP GUI for HTML patch may broaden supported operations, but ZTOAD must still advertise and test its frontend capabilities explicitly.

## Exact-candidate acceptance

Commit `31eca9936202b63874ba089e3744fe9971dfa0e4` implements the capability adapter. Its local source SHA-256 is `4b4823a5db169697696d71edf42b432ca66db0d8585c36066a3bd3817f61a2e5`. On A4H it was explicitly activated with 0 syntax errors, 2 pre-existing POSIX warnings, 57/57 Unit tests, equal active/inactive source, and no inactive ZTOAD child part.

A fresh WebGUI session accepted two sanitized read-only statements and executed the final `SELECT SINGLE mandt FROM t000`, proving the cursor-free selection contract. ALV displayed `000 / 1`, the success message reported one entry, F3 exited cleanly, and ST22 remained unchanged after 06:26:10 UTC. The shared object was then restored and activated to exact `origin/master`; this source-only candidate never switched the native-abapGit repository away from `master`.
