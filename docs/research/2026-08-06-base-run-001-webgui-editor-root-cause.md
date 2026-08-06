# BASE-RUN-001: WebGUI editor startup dump

_Research date: 2026-08-06 · affected system: A4H client 001, SAP_BASIS 758 SP02_

## Reproduction and original evidence

Launching ZTOAD in WebGUI reaches screen 0010 and terminates during `EDITOR_INIT`. The latest original pre-fix dump for user MARIAN is `RAISE_EXCEPTION` at `2026-08-06T07:56:39Z` in program `SAPLCNDP`.

The active-call chain is:

1. `ZTOAD` `EDITOR_INIT`
2. `CL_GUI_ABAPEDIT=>CONSTRUCTOR`
3. function module `DP_PUBLISH_URL`
4. `DATA_SOURCE_ERROR` raised from `CL_DATAPROVIDER=>NOCACHE_SYNC`

This is an uncaught classic exception inside the control constructor, so wrapping later editor method calls cannot recover startup.

## Root cause

The active A4H implementation of `CL_GUI_ABAPEDIT=>CONSTRUCTOR` calls its superclass and sets the requested source type. With the default source type `ABAP`, it unconditionally calls `DP_PUBLISH_URL` for namespace `LEXER_DATA`, installs a data-provider handler, and asks the frontend to load the ABAP lexer file. ZTOAD used the default and therefore selected this branch.

WebGUI marks the session through `CL_GUI_CONTROL=>WWW_ACTIVE`. SAP's own frontend-services source treats that flag as SAP GUI for HTML. In the failing request, the data provider has no usable cache and synchronous publication raises `DATA_SOURCE_ERROR`.

The deeper constraint is that the ABAP/source editor control is not usable in this WebGUI runtime. `CL_GUI_ABAPEDIT` suppresses superclass construction exceptions and continues. Avoiding only lexer publication can therefore leave a source-editor instance whose frontend handle was never created.

## TDD and spike sequence

The environment choice was first extracted into pure local class `LCL_EDITOR_CONFIGURATION`, allowing the frontend policy to be tested without constructing GUI controls.

### Red evidence

The legacy policy returned `ABAP` for every frontend. The focused WebGUI test expected the fallback and failed while all 18 pre-existing tests passed. This exact red candidate was activated and run on A4H, proving that the new test failed for the intended reason rather than because of a local-only test assumption.

### Rejected first green candidate

The first candidate returned source type `SQL` in WebGUI and kept `CL_GUI_ABAPEDIT`. It passed local abaplint, live syntax, and all 19 ABAP Unit tests, but the integration spike produced a different dump at `2026-08-06T09:30:59Z`:

- error: `RAISE_EXCEPTION`
- program: `CL_GUI_SOURCEEDIT=============CP`
- failing operation: `REGISTER_EVENT_COMPLETION`
- detail: `CNTL_ERROR` with an initial `h_control`
- caller: ZTOAD `EDITOR_INIT`

This disproved the assumption that changing the lexer type was sufficient. It skipped the original `DP_PUBLISH_URL` failure but retained an unsupported source-editor control.

### Final candidate

The final design introduces `LCL_EDITOR`, a narrow adapter over the two controls:

- WebGUI (`CL_GUI_CONTROL=>WWW_ACTIVE`) creates `CL_GUI_TEXTEDIT`.
- SAP GUI for Windows/Java creates `CL_GUI_ABAPEDIT` and retains F1 help, completion, quick info, insert-pattern events, and drag/drop.
- The adapter exposes only the text, selection, modification-status, visibility, insertion, and focus operations used by ZTOAD.
- WebGUI deliberately omits ABAP-editor-only F1/completion/drag-drop features because their control is unsupported there.
- `LCL_EDITOR_CONFIGURATION` returns `TEXT` for WebGUI and `ABAP` elsewhere; both branches have harmless, short ABAP Unit tests.

The change does not touch parsing, generated SQL, authorization, persistence, dynpros, or serialized repository metadata.

## Final validation evidence

### Local

- `npm ci`: passed; 0 dependency vulnerabilities.
- `npm test`: passed with 0 configured abaplint findings.
- `git diff --check`: passed.
- Full diagnostic inventory: 1,878 findings across 58 rules, compared with 1,857 across 57 on `master`. Nineteen explained additions are naming diagnostics for the new adapter API; two are classic-exception diagnostics retained to preserve the existing Control Framework `sy-subrc` error contract. The default profile simultaneously requires Hungarian-style method parameter prefixes and rejects those prefixes through `no_prefixes`; no suppression was added to manipulate the count.

### NPL SAP_BASIS 750

NPL was used only through ARC-1/ADT. Its connection and disposable report lifecycle are proven, but exact ZTOAD activation remains blocked because transparent table `ZTOAD` is absent and SAP_BASIS 750 has no ADT transparent-table creation endpoint. No substitute structure was created and no 7.50 pass is claimed. See [the NPL validation dossier](2026-08-06-npl-adt-only-validation.md).

### A4H SAP_BASIS 758

- Exact final source activated; active and inactive SHA-256 values match with no divergence.
- SAP syntax: 0 errors, the same 4 known warnings (3 POSIX deprecations and unsupported `C_DB_EXECUTE`).
- ABAP Unit: 19 passed, 0 failed, including both editor-policy tests.
- ATC `ABAP_CLOUD_READINESS`: 768 findings (463 priority 1, 305 priority 2); architectural debt inventory, not a zero gate.
- ATC `S4HANA_READINESS_2023`: no finding rows returned, but the known missing prerequisite checks make this non-authoritative.
- Fresh standalone WebGUI launch after final activation: screen 0010 and the plain text editor rendered; `SELECT SINGLE mandt FROM t000` could be entered.
- Post-smoke ST22: no new dump; the newest entry remains the rejected intermediate spike at `2026-08-06T09:30:59Z`.

The query could not be dispatched because A4H reports `Status STATUS010 der Oberfläche ZTOAD fehlt`. The repository's `ztoad.prog.xml` contains `STATUS010`, so this is installation/metadata drift covered by `BASE-BUG-007`, not an editor-startup regression. `BASE-RUN-001` is therefore fixed at its editor startup/render/input boundary; complete query execution remains blocked by the separate structural-installation finding.

## SAP guidance used

SAP's ABAP documentation describes Control Framework classes as wrappers for GUI controls and recommends separating presentation, application, and persistence concerns in classic dynpro applications. The active standard-class implementations on A4H provide the release-exact behavior used for this diagnosis. No matching corrective SAP Note for this exact `CL_GUI_ABAPEDIT`/`DP_PUBLISH_URL` failure was found by the SAP Notes search.

References:

- [SAP ABAP documentation: Control Framework](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENCONTROL_FRAMEWORK_GLOSRY.html)
- [SAP ABAP programming guideline: separation behind class interfaces](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENENCAP_CLASS_INTERF_GUIDL.html)
- [SAP ABAP documentation: custom controls](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENDYNPRO_CUSTOM_CONTROLS.html)
