# BASE-BUG-007 complete-installation research

_Researched 2026-08-06 and validated 2026-08-07 against local `master` `612330c`, A4H/SAP_BASIS 758 through ARC-1/ADT and native abapGit 1.133.0, current abapGit program deserialization source, and SAP ABAP Keyword Documentation._

## Question

Why does a direct `ZTOAD` transaction reach dynpro 0010 on A4H but report that GUI status `STATUS010` is missing, even though `src/ztoad.prog.xml` contains that status, and what constitutes a supported installation test?

## Evidence

The initial Git repository already contained the complete native-abapGit object closure:

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

## Structural repair and live validation

The repair followed the coordinated native-abapGit path on 2026-08-07:

1. Local and origin `master` were identical at `612330c`. Repository `000000000017` was refreshed on `master`; its status showed the program drift separately from unrelated package and table drift.
2. Only `PROG ZTOAD` was selected for the pull. The activation worklist contained `REPT ZTOAD`, `CUAD ZTOAD`, and dynpros 0010, 0100, 0200, and 0300. All were activated through the native worklist.
3. The live installation contract then returned zero inactive ZTOAD parts. Active and inactive main source were equal, and the active server-normalized source SHA-256 was `21ef81d0b925bca71182822a0e9650cb80b32c6e3fd3ae4d1d73576011cb74b7`.
4. Active SAP syntax returned zero errors and the two known POSIX warnings. All 55 ABAP Unit tests passed. Statement/branch/procedure coverage was 25.07%/24.10%/16.87%.
5. Complete ATC variant `ABAP_CLOUD_READINESS` reproduced the 668-finding baseline (462 P1, 206 P2). `S4HANA_READINESS_2023` again returned no rows but remains incomplete because its prerequisite checks are unavailable.

The follow-up native round trip revealed a serializer migration rather than product drift. Native abapGit 1.133.0 removes each dynpro's `FLOW_LOGIC` and `SPACES` records from `ztoad.prog.xml` and writes the same flow source into four `ztoad.prog.screen_<number>.abap` files. The old and new representations were compared statement by statement. Only `PROG ZTOAD` was staged and pushed in commit `b1c2aa9`; the unchanged report source SHA-256 is `87df3e26ef490e18ac22a3a761094f33b4ed8acb1ebd945d6023c6479bb8a29d`. Unrelated `DEVC` deletion and `TABL` drift remained unselected. The installation contract now requires those four flow-logic files and their essential PBO/PAI statements.

After confirming the feature-branch program was clean, the shared repository link was restored to `refs/heads/master`; ARC-1's branch endpoint required the full ref, and `list_repos` was used to verify the result. The live inactive-child contract remained green. Native status will deliberately show the captured program serializer delta against old `master` until this PR is merged; it must not be pulled back over the active candidate.

## Runtime boundary exposed after the repair

A fresh FLP/WebGUI launch now renders the complete editor, DDIC controls, title, and `STATUS010`; the former installation error is gone. Dispatching the sanitized query `SELECT SINGLE mandt FROM t000` reaches `SY-UCOMM = EXECUTE`, proving that the structural blocker is repaired. It then creates a new `MESSAGE_TYPE_X` dump at 2026-08-07 04:31:22 UTC in `SAPLOLEA`, termination point `AC_SYSTEM_FLUSH` line 35 with CNDP message 006.

That failure begins after the installation acceptance boundary and is recorded as `BASE-RUN-006`, not folded back into `BASE-BUG-007`. The first source-level suspect is the result/control flush path (`RESULT_DISPLAY` configures the ALV and explicitly calls `CL_GUI_CFW=>FLUSH`), but the failing control and root cause have not yet been proven. The overall WebGUI query smoke therefore remains red even though the structural installation gate is green.

NPL remains an ADT-only SAP_BASIS 750 target and currently lacks ZTOAD's real transparent table. It cannot prove this native-abapGit structural round trip under the present boundary. That gate remains explicitly prerequisite-blocked rather than being replaced with GUI automation or a DDIC structure.

## Process finding

The written workflow already required child-part checks, but it had no executable definition of installation closure. The new contract makes the distinction operational:

- repository serialization proves what Git can install;
- the inactive-child inventory proves what SAP has activated;
- native-abapGit status proves system/Git round-trip cleanliness;
- runtime smoke proves the activated metadata is usable.

All four are required for a structural program change. Main-source equality alone is never sufficient. The final smoke also showed why acceptance steps need explicit boundaries: installation can be proven green while the next runtime layer fails, and those findings should remain separately reproducible.

## Sources

- [SAP `SET PF-STATUS` documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPSET_PF-STATUS_DYNPRO.html)
- [SAP dynpro GUI-status example](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENDYNPRO_GUI_STATUS_ABEXA.html)
- [abapGit supported object types](https://docs.abapgit.org/user-guide/reference/supported.html)
- [abapGit program object deserializer](https://github.com/abapGit/abapGit/blob/main/src/objects/zcl_abapgit_object_prog.clas.abap)
- [abapGit program serialization/deserialization helper](https://github.com/abapGit/abapGit/blob/main/src/objects/zcl_abapgit_objects_program.clas.abap)
