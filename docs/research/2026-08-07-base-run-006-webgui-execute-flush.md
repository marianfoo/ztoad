# BASE-RUN-006 initial characterization: WebGUI execute flush

_Observed 2026-08-07 on A4H client 001, SAP_BASIS 758 SP02, after the complete `BASE-BUG-007` native-abapGit activation. This note records a sanitized reproduction boundary, not a finished root-cause claim._

## Reproduction

1. Start a fresh FLP/WebGUI transaction `ZTOAD`.
2. Confirm the editor, DDIC controls, title, and GUI status render without the former `STATUS010` error.
3. Enter the read-only query `SELECT SINGLE mandt FROM t000`.
4. Choose **Execute**.

The transaction leaves the application and creates a new ST22 entry. No write statement, native SQL, production data, or confidential query text is involved.

## Sanitized dump evidence

- timestamp: 2026-08-07 04:31:22 UTC;
- runtime error: `MESSAGE_TYPE_X`;
- termination program/form: `SAPLOLEA`, `AC_SYSTEM_FLUSH`, line 35;
- Control Framework message: CNDP 006, error processing a control;
- main program/event: `ZTOAD`, `START-OF-SELECTION`, with screen 0010 active;
- command state: `SY-UCOMM = EXECUTE` and GUI status `STATUS010`.

This proves the inactive GUI-status installation defect is no longer the dispatch blocker. It does not yet prove which frontend control fails.

## Source path and current hypothesis

`USER_COMMAND_0010` calls `QUERY_PROCESS`. For a successful SELECT, the form generates and runs the read-only subroutine, refreshes DDIC state, and calls `RESULT_DISPLAY`. That form configures `CL_GUI_ALV_GRID`, reads splitter state, and explicitly calls `CL_GUI_CFW=>FLUSH` before revealing the result row. The dump shape makes this result/control boundary the first place to instrument, but an earlier queued editor/tree/splitter operation could also be the command that the flush reports.

Do not fix this by removing every flush or by suppressing the dump. Research must isolate the first unsupported/malformed queued control operation and verify whether the WebGUI result control, splitter call, DDIC refresh, or another queued operation is responsible.

## TDD entry criteria

1. Reproduce in a fresh session and capture the ST22 before/after identifiers.
2. Spike one phase boundary at a time with the same sanitized query: execute without result presentation, result-object setup without explicit reveal, splitter height read, and explicit flush.
3. Once the failing operation is known, add the smallest pure policy/orchestration test that is red on the original path. If the behavior is frontend-only, keep an explicit live integration regression as a required gate rather than pretending ABAP Unit can prove control support.
4. Preserve desktop behavior and ABAP 7.50 syntax. Use ARC-1/ADT only on NPL; browser validation remains A4H-only.
5. Accept the fix only when syntax, all Unit tests, ATC delta, fresh read-only result smoke, and ST22 delta are green.

## Status

Open. This finding independently blocks complete WebGUI query smoke; it does not reopen the structurally green `BASE-BUG-007` installation closure.
