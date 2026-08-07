# NPL SAP_BASIS 750 ADT-only validation target

_Research date: 2026-08-06 · updated: 2026-08-07 · system: NPL client 001 · validation interface: ARC-1 over ADT_

## Decision and scope

NPL is the minimum-release compiler and ABAP Unit target for ZTOAD. Per maintainer direction, it is not used for FLP, WebGUI, SAP GUI, or browser automation during validation. Source deployment, activation, syntax, ABAP Unit, ATC, and object-state evidence use ARC-1 and ADT APIs. Browser smoke testing remains an A4H/SAP_BASIS 758 responsibility. The maintainer used native abapGit once to provision the complete offline repository because the real transparent table cannot be created through the 7.50 ADT surface.

The separate Codex MCP profile is named `arc-1-750`. It is pinned to the published ARC-1 1.0.2 CLI, identifies the destination as on-premise SAP_BASIS 750, and keeps data preview and free SQL disabled. The maintainer explicitly selected the unrestricted `*` package ceiling for both ARC-1 profiles; SAP authorization and the independent write-enable flags remain effective. Credentials remain outside the repository.

## Live discovery

ARC-1 authenticated as the configured NPL developer and reported:

| Component | Release | SP |
|---|---:|---:|
| SAP_BASIS | 750 | 02 |
| SAP_ABA | 750 | 02 |
| SAP_UI | 750 | 02 |
| SAP_GWFND | 750 | 02 |

HANA, classic CTS, CDS, RAP, and UI5 endpoints are present. Native abapGit ADT integration and gCTS are unavailable. These missing integrations do not prevent source activation, syntax checks, or ABAP Unit through ADT.

## Usability proof

A disposable `$TMP` report, `ZARC1_ZTOAD_750_PROBE`, was created through `SAPWrite`, activated, syntax-checked, and executed with `SAPDiagnose action=unittest`. Its harmless, short unit test passed. The report was then deleted and its absence confirmed. This proves the ARC-1 read/write/activate/syntax/unit/cleanup lifecycle without SAP GUI or browser access.

## Original ZTOAD deployment blocker

Program `ZTOAD` and transparent table `ZTOAD` were not installed on NPL at the time of the original probe. The report could not be compiled faithfully without the table because its source contains typed references and Open SQL operations against `ZTOAD`.

SAP_BASIS 750 does not expose the ADT transparent-table create endpoint `/sap/bc/adt/ddic/tables`; that editor endpoint is available only on newer releases. The 7.50 structures endpoint must not be used as a substitute: it would create an internal structure rather than a transparent table and would make the validation result invalid. ARC-1 correctly refuses this unsafe write. This limitation is independently documented and live-probed in the ARC-1 research dossier `docs/research/2026-07-29-nw750-fixture-create-surface.md` in the ARC-1 repository.

At that point:

- the NPL connection and source/unit lifecycle are usable;
- exact ZTOAD activation, syntax, Unit, and ATC remained blocked until transparent table `ZTOAD` was provisioned once outside ADT;
- no gate is reported as passed from a stub structure or partial source;
- after the real table exists, ARC-1 can update the report, activate it, and run syntax, ABAP Unit, and ATC entirely through ADT.

## Offline native-abapGit provisioning and completed gate

On 2026-08-07 the maintainer created native abapGit 1.134.0 offline repository `ZTOAD` in local package `$ZTOAD2`, imported the ZIP generated from exact `origin/master` commit `d532b2e`, selected only the four intended repository objects, pulled, and activated them:

- `PROG ZTOAD`, including GUI status, texts, and dynpros 0010, 0100, 0200, and 0300;
- `TABL ZTOAD` as a real transparent table;
- `TRAN ZTOAD`;
- `SUSO ZTOAD_AUTH`.

ARC-1 then established the first complete minimum-release baseline:

| Gate | Restored master | `BASE-BUG-001` compatibility candidate `9e8d881` |
|---|---:|---:|
| Active SAP syntax | 0 errors | 0 errors |
| ABAP Unit | 66 passed, 1 failed | 67 passed, 0 failed |
| ATC `DEFAULT` | 88 findings | 88 findings |
| Active/inactive source | Equal | Equal |
| Inactive ZTOAD parts | 0 | 0 |

The sole master failure uses `COUNT( FIELDNAME )`, a grammar form rejected by SAP_BASIS 750. The candidate changes only that regression fixture to `COUNT( DISTINCT FIELDNAME )`; see [the focused investigation](2026-08-07-base-bug-001-npl-count-grammar.md).

The table activated with a warning because its serialized enhancement category is missing. NPL normalized it to `#NOT_CLASSIFIED`, leaving a table diff. This is tracked separately as `BASE-DDIC-001`; it does not invalidate the proof that the installed object is a real transparent table or the source candidate's syntax/Unit result.

## Tooling observations

- ARC-1 1.0.2 detects SAP_BASIS 750 correctly, but `SAPLint list_rules` reports an on-premise `v702` syntax profile with an unknown ABAP version. Repository abaplint and the live SAP compiler remain authoritative until ARC-1 aligns that preset.
- `SAPRead PROG ZTOAD` returned a misleading class-local-test-include hint for an absent report.
- `SAPRead DEVC ZTOAD` returned unrelated package contents for a nonexistent package. Do not use that response as installation evidence; use exact object reads/searches.

These are ARC-1 quality findings, not ZTOAD product failures. They should be considered when interpreting automated bootstrap output.
