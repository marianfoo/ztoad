# NPL SAP_BASIS 750 ADT-only validation target

_Research date: 2026-08-06 · system: NPL client 001 · interface: ARC-1 over ADT only_

## Decision and scope

NPL is the minimum-release compiler and ABAP Unit target for ZTOAD. Per maintainer direction, it is not used for FLP, WebGUI, SAP GUI, or browser automation. All NPL operations must use ARC-1 and ADT APIs. Browser smoke testing remains an A4H/SAP_BASIS 758 responsibility.

The separate Codex MCP profile is named `arc-1-750`. It is pinned to the published ARC-1 1.0.2 CLI, identifies the destination as on-premise SAP_BASIS 750, permits controlled writes only to the ZTOAD test package allowlist, and keeps data preview and free SQL disabled. Credentials remain outside the repository.

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

## ZTOAD deployment blocker

Program `ZTOAD` and transparent table `ZTOAD` are not installed on NPL. The report cannot be compiled faithfully without the table because its source contains typed references and Open SQL operations against `ZTOAD`.

SAP_BASIS 750 does not expose the ADT transparent-table create endpoint `/sap/bc/adt/ddic/tables`; that editor endpoint is available only on newer releases. The 7.50 structures endpoint must not be used as a substitute: it would create an internal structure rather than a transparent table and would make the validation result invalid. ARC-1 correctly refuses this unsafe write. This limitation is independently documented and live-probed in the ARC-1 research dossier `docs/research/2026-07-29-nw750-fixture-create-surface.md` in the ARC-1 repository.

Therefore:

- the NPL connection and source/unit lifecycle are usable;
- exact ZTOAD activation, syntax, Unit, and ATC remain blocked until transparent table `ZTOAD` is provisioned once by a mechanism outside the maintainer's current ADT-only boundary;
- no gate is reported as passed from a stub structure or partial source;
- after the real table exists, ARC-1 can create/update the report, activate it, and run syntax, ABAP Unit, and ATC entirely through ADT.

## Tooling observations

- ARC-1 1.0.2 detects SAP_BASIS 750 correctly, but `SAPLint list_rules` reports an on-premise `v702` syntax profile with an unknown ABAP version. Repository abaplint and the live SAP compiler remain authoritative until ARC-1 aligns that preset.
- `SAPRead PROG ZTOAD` returned a misleading class-local-test-include hint for an absent report.
- `SAPRead DEVC ZTOAD` returned unrelated package contents for a nonexistent package. Do not use that response as installation evidence; use exact object reads/searches.

These are ARC-1 quality findings, not ZTOAD product failures. They should be considered when interpreting automated bootstrap output.
