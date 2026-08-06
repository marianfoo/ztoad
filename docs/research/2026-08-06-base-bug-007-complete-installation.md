# BASE-BUG-007 complete-installation research

_Researched 2026-08-06 against local `master` `612330c`, A4H/SAP_BASIS 758 through ARC-1/ADT, current abapGit program deserialization source, and SAP ABAP Keyword Documentation._

## Question

Why does a direct `ZTOAD` transaction reach dynpro 0010 on A4H but report that GUI status `STATUS010` is missing, even though `src/ztoad.prog.xml` contains that status, and what constitutes a supported installation test?

## Evidence

The Git repository already contains the complete native-abapGit object closure:

- `ztoad.prog.abap` plus `ztoad.prog.xml` using `LCL_OBJECT_PROG`;
- dynpros 0010, 0100, 0200, and 0300 in the program XML;
- GUI statuses/titlebars `STATUS010`, `STATUS200`, and `STATUS300` in the program XML;
- `ztoad.tabl.xml`, `ztoad_auth.suso.xml`, and `ztoad.tran.xml` with their native serializers.

The report sets each serialized GUI status in PBO. SAP's `SET PF-STATUS` documentation says the status is normally taken from the current main program; if the status is unavailable, the runtime supplies an empty status instead. The observed `STATUS010` message is therefore consistent with missing or inactive GUI metadata, not with a parser or editor defect.

The decisive A4H evidence is the ADT inactive-object inventory. It contains these seven ZTOAD parts:

| ADT part | Meaning |
|---|---|
| `PROG/P ZTOAD` | report source/program part |
| `PROG/PCA ZTOAD` | CUA/GUI status part |
| `PROG/PS ZTOAD 0010` | main dynpro |
| `PROG/PS ZTOAD 0100` | editor subscreen |
| `PROG/PS ZTOAD 0200` | save dialog |
| `PROG/PS ZTOAD 0300` | options dialog |
| `PROG/PX ZTOAD` | text elements |

This remains possible even when active and inactive **main source** text is identical. The composite child inventory is the missing proof.

Current abapGit program deserialization confirms the required lifecycle. `ZCL_ABAPGIT_OBJECT_PROG` deserializes the program, dynpros, and CUA separately. Its program helper writes report source inactive and queues `REPS`; writes every screen and queues `DYNP`; writes CUA state inactive through `RS_CUA_INTERNAL_WRITE` and queues `CUAD`. A source-only ARC-1 write followed by main-program activation is not equivalent to that complete deserialization/activation queue.

## Root cause

`BASE-BUG-007` is currently an **installation-state defect**, not missing Git metadata. A4H has a partially inactive composite program: the serialized CUA, four dynpros, text elements, and program part were not brought to one fully active native-abapGit state. Repeated direct source deployment can refresh or activate the report source while leaving the installation closure broken.

Hand-editing `ztoad.prog.xml`, adding another source copy, or changing `SET PF-STATUS` would hide rather than fix that root cause. The correct repair is a coordinated native-abapGit pull/deserialization of exact `master`, activation of every queued child part, and a clean follow-up repository check.

## Executable red contract

`scripts/installation-contract.mjs` now provides two complementary gates:

1. The normal local/CI test checks that all required object files, four dynpros, and three GUI statuses remain serialized. This prevents a future source-only distribution from silently becoming the supported installation.
2. `--inactive-objects <json>` consumes either direct ARC-1 inactive-object JSON or the ARC-1 CLI MCP envelope and fails when any ZTOAD composite program part is pending activation.

The pure contract has four passing Node tests, including the seven-part failure shape. Running it against the live A4H inventory is RED with the exact seven entries above. The evidence file is temporary and sanitized; user, transport, URI, credential, and unrelated-object data are not committed.

Example evidence capture and check:

```sh
arc1 call SAPRead --arg type=INACTIVE_OBJECTS --output json > /tmp/ztoad-inactive.json
node scripts/installation-contract.mjs --inactive-objects /tmp/ztoad-inactive.json
```

The command is green only when the repository closure is present **and** A4H has no inactive ZTOAD program parts. It does not replace native-abapGit status, SAP activation/syntax, ABAP Unit, ATC, or runtime smoke.

## Implementation and validation decision

When GitHub/native-abapGit connectivity is reliable again:

1. Confirm local and origin `master` are identical and reserve the shared A4H `ZTOAD` package for this repair.
2. Refresh native abapGit repository `000000000017`, inspect all drift, and keep it on `master`.
3. Pull/deserialise the complete repository and activate every queued ZTOAD object/child part. Do not use **Add All**, stage unrelated A4H drift, or construct XML manually.
4. Require a clean native-abapGit check and a green live installation-closure command.
5. Re-run active syntax, all ABAP Unit tests, both recorded ATC variants with prerequisite status, and active/inactive composite state.
6. Start a fresh A4H transaction and dispatch only `SELECT SINGLE mandt FROM t000`; verify the result path and ST22 delta.
7. Re-export/compare the complete object set. Any serializer drift must be reviewed and committed on this branch; an unexported system-only fix is not complete.

NPL remains an ADT-only SAP_BASIS 750 target and currently lacks ZTOAD's real transparent table. It cannot prove this native-abapGit structural round trip under the present boundary. That gate must remain explicitly prerequisite-blocked rather than being replaced with GUI automation or a DDIC structure.

## Process finding

The written workflow already required child-part checks, but it had no executable definition of installation closure. The new contract makes the distinction operational:

- repository serialization proves what Git can install;
- the inactive-child inventory proves what SAP has activated;
- native-abapGit status proves system/Git round-trip cleanliness;
- runtime smoke proves the activated metadata is usable.

All four are required for a structural program change. Main-source equality alone is never sufficient.

## Sources

- [SAP `SET PF-STATUS` documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPSET_PF-STATUS_DYNPRO.html)
- [SAP dynpro GUI-status example](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENDYNPRO_GUI_STATUS_ABEXA.html)
- [abapGit supported object types](https://docs.abapgit.org/user-guide/reference/supported.html)
- [abapGit program object deserializer](https://github.com/abapGit/abapGit/blob/main/src/objects/zcl_abapgit_object_prog.clas.abap)
- [abapGit program serialization/deserialization helper](https://github.com/abapGit/abapGit/blob/main/src/objects/zcl_abapgit_objects_program.clas.abap)
