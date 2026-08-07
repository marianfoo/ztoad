# BASE-DDIC-001: explicit table enhancement category

_Research date: 2026-08-07 · targets: SAP_BASIS 750 and SAP_BASIS 758_

## Outcome

Table `ZTOAD` should declare `#NOT_EXTENSIBLE`. The table is an internal persistence detail of the report, exposes no append contract, and contains a deep `STRING` component. Allowing arbitrary extensions would broaden a compatibility surface the project does not test or support.

The current serializer omits `DD02V-EXCLASS`. Both SAP targets consequently expose the active table as `#NOT_CLASSIFIED`; NPL also warned during the offline pull and produced a persistent local/remote table diff.

## SAP guidance

SAP documents five enhancement categories. It explicitly states that `#NOT_CLASSIFIED` exists only for already-existing unclassified objects and should not be used when an object is created or changed. The current ABAP keyword documentation describes `#NOT_EXTENSIBLE` as “cannot be enhanced”. The extensible categories allow respectively character-like flat, character/numeric flat, or arbitrary/deep append components.

Because `ZTOAD` is being changed and has no public extension point, `#NOT_EXTENSIBLE` is the narrow, explicit category. `#EXTENSIBLE_CHARACTER` and `#EXTENSIBLE_CHARACTER_NUMERIC` are also incompatible with the existing deep `QUERY` field; `#EXTENSIBLE_ANY` would deliberately promise an extension contract that does not exist.

References:

- [SAP Help: Structure Annotations, ABAP Platform 2023 FPS02](https://help.sap.com/docs/ABAP_PLATFORM_NEW/c238d694b825421f940829321ffa326a/afd07524f9ab41e0995ddd9cfdf148c2.html?locale=en-US&state=PRODUCTION&version=202310.002#loio4bfbcb53a8784972a3be0efabc1e81f5)
- [ABAP Keyword Documentation: DDIC structure properties](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENDDICDDL_DEFINE_STRUCT_PROPS.html)

## abapGit representation

The official abapGit TABL DDL serializer maps these values:

| DD02V `EXCLASS` | DDL category |
|---:|---|
| `0` | `#NOT_CLASSIFIED` |
| `1` | `#NOT_EXTENSIBLE` |
| `2` | `#EXTENSIBLE_CHARACTER` |
| `3` | `#EXTENSIBLE_CHARACTER_NUMERIC` |
| `4` | `#EXTENSIBLE_ANY` |

Therefore the repository contract can require `<EXCLASS>1</EXCLASS>`. The value must be produced by changing the table in SAP and exporting `TABL ZTOAD` with native abapGit; it must not be hand-authored into serializer XML.

Reference: [abapGit TABL DDL serializer](https://github.com/abapGit/abapGit/blob/88524f72ec9177efd8445ff209c7a8218b216f7a/src/objects/tabl/zcl_abapgit_object_tabl_ddl.clas.abap#L720-L735)

## Compatibility and risk

- The category is metadata supported by both 7.50 and 758.
- No column, key, type, delivery class, technical setting, or stored row changes.
- Existing code has no append dependency; live structure discovery found no append on NPL. A4H where-used structure discovery is unavailable through its older ARC-1 adapter, so the native-abapGit diff and activation preaudit must remain authoritative there.
- Rollback is a reviewed native-abapGit restoration of the previous table serialization. Returning to unclassified metadata is not recommended, but it does not require a database conversion.

## Native round-trip evidence

- Red contract commit: `fb60eca`; `npm run test:repository` failed only because `<EXCLASS>1</EXCLASS>` was absent.
- Native-abapGit candidate commit: `4206a1a`; table XML SHA-256 `0a7b98b6c073e5062c56bfd314dc297ecd88dc0ea685bee643caabc9a76a1f40`.
- A4H active candidate: `#NOT_EXTENSIBLE`, all seven fields unchanged, equal active/inactive table source, zero inactive ZTOAD parts, report syntax 0 errors plus two pre-existing POSIX warnings, and 67/67 Unit. `S4HANA_READINESS_2023` again returned zero rows with its known prerequisite limitation; Cloud ATC remained the unchanged legacy baseline.
- The current serializer also added `MASTERLANG E` and removed redundant per-field `TABNAME`, `POSITION`, and `DDLANGUAGE` values. Field order, names, types, key, table class, delivery class, and technical settings are unchanged. This canonicalization is reviewed as part of the dedicated structural change.
- Native abapGit staged only `TABL ZTOAD`; the pre-merge report drift was explicitly left unselected. A4H was then switched and pulled back to full `refs/heads/master`, activating current master report source and the pre-change unclassified table with equal active/inactive state.
- Exact NPL import archive: `/tmp/ztoad-base-ddic-001.zip`, SHA-256 `a5c5745c55304e34f334ddb6b1e4ec7c4c3fbde9cf6ce46d01264f963059a4c5`. The archive was imported into the existing `$ZTOAD2` offline repository. All four repository objects were accidentally selected; this did not widen the candidate because its program was exact current `master` and its transaction/authorization object were unchanged. The subsequent package-deletion proposal was left unselected.
- NPL explicitly activated both `TABL ZTOAD` and `PROG ZTOAD`. The active table reports `#NOT_EXTENSIBLE` with the original seven fields, the report has zero syntax errors and 67/67 passing Unit tests, `DEFAULT` ATC remains at its complete 88-finding baseline (3 P1, 4 P2, 81 P3), and the inactive inventory contains no ZTOAD object.
- ARC-1 1.0.2's direct `TABL` active object-state path returned 404 on NPL even while its automatic table read returned the active object and its inactive read explicitly reported that no inactive draft exists. Explicit activation, both reads, exact field/category comparison, object search, and the global inactive inventory jointly establish the state; the inconsistent endpoint is tracked as an ARC-1 adapter limitation.
