# BASE-BUG-006 transaction research

_Date: 2026-08-06 · finding: `BASE-BUG-006` · issue: [#2](https://github.com/marianfoo/ztoad/issues/2)_

## Problem and red baseline

The red repository baseline had no `src/ztoad.tran.xml`. A4H's ADT transaction read for absent `ZTOAD` returned empty description, program, and package fields. The stable direct URLs therefore had no repository-managed transaction to resolve:

- FLP: `#Shell-startGUI?sap-ui2-tcode=ZTOAD`
- standalone WebGUI: `~transaction=ZTOAD`

Issue #2 asks for a transaction code and reports that a locally created transaction could not be committed. This is a structural-repository problem: source-only editing cannot create a complete `TRAN` object and hand-writing its XML would bypass the native serializer.

## Transaction type decision

SAP distinguishes a report transaction, which starts an executable program through `SUBMIT`, from a dialog transaction, which loads a program and starts a specific dynpro after `LOAD-OF-PROGRAM`.

ZTOAD is an executable report (`SUBC=1`). Its entry point is:

```abap
START-OF-SELECTION.
  CALL SCREEN 10.
```

Therefore `TRAN ZTOAD` should be a **report transaction** for program `ZTOAD`, not a dialog transaction aimed directly at screen `0010`. A direct dynpro transaction would bypass the report event sequence and make future initialization behavior surprising. The canonical generated selection-screen number for the report transaction is `1000`; because ZTOAD has no visible selection parameters, startup proceeds to `START-OF-SELECTION` and screen `0010`.

The transaction must explicitly support SAP GUI for HTML and SAP GUI for Windows. HTML support is required for the A4H FLP/WebGUI acceptance path; Windows support preserves the original desktop use case. SAP GUI for Java is not claimed until it has a live compatibility test.

## Serialization decision

abapGit lists `TRAN` as a supported on-premise object type. Its current `LCL_OBJECT_TRAN` serializer reads `TSTC`, `TSTCC`, `TSTCT`, optional `TSTCP`, authorization assignments, and translations. It classifies report transactions from the `TSTC-CINFO` report bit and recreates them through SAP's transaction insertion API.

Consequences for this fix:

1. Create `ZTOAD` in A4H transaction maintenance with package `ZTOAD` and the existing workbench request.
2. Let native abapGit serialize the active object; do not construct `ztoad.tran.xml` by hand.
3. Review the resulting `TSTC`, `TSTCC`, and `TSTCT` semantics and commit only `TRAN ZTOAD` from the SAP system.
4. Keep a repository contract test so removing or changing the required launcher fails `npm test` even though abaplint cannot infer that a transaction is mandatory from the report alone.

abapGit intentionally serializes only active, consistent object state and excludes system-specific users, timestamps, and inactive versions. A native round trip is therefore both the portability test and the source of truth for the XML format.

## Compatibility and clean-core assessment

- `TRAN` is supported by native abapGit for classic on-premise systems, including the SAP_BASIS 750 and 758 targets.
- This launcher adds no ABAP source and no released-API dependency. It does add the normal transaction-start authorization gate (`S_TCODE`) before ZTOAD's existing application authorization checks.
- A classic SE93 transaction is not an ABAP Cloud artifact. ZTOAD remains an on-premise compatibility product and does not become clean-core Level A through this change.
- NPL is intentionally ADT-only. ARC-1 can read transaction metadata but the available ADT surface cannot create or native-abapGit-round-trip `TRAN`; no NPL GUI fallback is allowed. That live structural gate must be reported as blocked, not passed.
- A4H currently lacks installed GUI status `STATUS010` (`BASE-BUG-007`). Direct launch can prove transaction resolution, report entry, screen rendering, and dump behavior, but the first query dispatch remains a separate blocked gate.

## Acceptance evidence required

- focused repository test is red before serialization and green afterward;
- `npm ci`, configured abaplint, and the full diagnostic abaplint profile are reviewed;
- native serialization reports transaction `ZTOAD` mapped to program `ZTOAD`; the current ARC-1 `TRAN` reader is not authoritative for report-transaction program metadata and returns an empty program after creation;
- native abapGit reports the transaction clean after the push/round trip;
- direct FLP and standalone WebGUI URLs reach ZTOAD without an unknown-transaction error;
- A4H active source, syntax, all ABAP Unit tests, selected ATC variants, and ST22 delta are checked;
- NPL ARC-1/ADT reads and available lifecycle gates are recorded without browser, FLP, WebGUI, or SAP GUI automation.

## Implemented result

Native abapGit serialized `src/ztoad.tran.xml` with serializer `LCL_OBJECT_TRAN`. Its `TSTC` record identifies `ZTOAD`, program `ZTOAD`, selection screen `1000`, and the report-transaction flag. `TSTCC` enables WebGUI and Windows GUI; `TSTCT` contains the English short text `ZTOAD SQL query tool`. Only this transaction object was staged. Existing A4H drift in program screens, program metadata, table metadata, and package metadata was left out of the commit.

Both direct A4H launch forms reached the ZTOAD editor without an unknown-transaction error. A pre/post ST22 comparison found no new dump. The screen still reports missing GUI status `STATUS010`, which confirms that transaction resolution is fixed while `BASE-BUG-007` remains independently reproducible.

On NPL, exact ADT repository search returns no ZTOAD objects; report and table reads return not found. The ARC-1 transaction reader returns an all-empty placeholder for an absent transaction, so it cannot be treated as installation evidence. Because the real table and report are absent and the ADT-only boundary has no native `TRAN` round trip, exact SAP_BASIS 750 structural installation remains blocked.

## Sources

- [SAP ABAP Keyword Documentation: report transaction](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENREPORT_TRANSACTION_GLOSRY.html)
- [SAP ABAP Keyword Documentation: dialog transaction](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENDIALOG_TRANSACTION_GLOSRY.html)
- [SAP ABAP Keyword Documentation: transaction code](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENTRANSACTION_CODE_GLOSRY.html)
- [abapGit supported object types](https://docs.abapgit.org/user-guide/reference/supported.html)
- [abapGit serializer overview](https://docs.abapgit.org/development-guide/serializers/overview.html)
- [abapGit `TRAN` serializer](https://github.com/abapGit/abapGit/blob/main/src/objects/zcl_abapgit_object_tran.clas.abap)
