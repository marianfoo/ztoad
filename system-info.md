# System Info: A4H / ZTOAD test matrix

_Updated: 2026-08-07_ · _Source: live ARC-1 discovery on A4H and NPL, native abapGit, SAP syntax/Unit/ATC runs, and A4H WebGUI smoke testing_

## Identity

| Field | Value |
|---|---|
| SID | A4H |
| System type | on-premise S/4HANA |
| Release | ABAP Platform 2023 / SAP_BASIS 758 SP02 |
| Kernel | Not reported by the available ADT discovery endpoints |
| Host | Private HTTPS reverse proxy loaded from ignored `.env` variable `SAP_URL`; no SAP port suffix |
| Client | 001 |
| Language | EN |
| User | MARIAN |

## Core Components

| Component | Release | SP | Description |
|---|---:|---:|---|
| SAP_BASIS | 758 | 02 | ABAP platform basis |
| SAP_ABA | 75I | 02 | Cross-application basis |
| SAP_UI | 758 | 02 | UI technology |
| SAP_GWFND | 758 | 02 | Gateway foundation |
| S4FND | 108 | 02 | S/4HANA foundation |

## Feature Availability

| Feature | Available | Mode | Note |
|---|---|---|---|
| HANA | Yes | database | Database-specific paths can be tested, but tests must remain safe and sanitized |
| RAP / CDS | Yes | ADT | Not used by the current classic report |
| abapGit | Yes | native, online | `ZABAPGIT` 1.133.0; ZTOAD repository key `000000000017`, package `ZTOAD`, verified on full ref `refs/heads/master` after the structural-object round trip |
| gCTS | Endpoint available | no ZTOAD repository | Native abapGit remains the selected round-trip mechanism |
| Transports | Yes | CTS | Transportable package `ZTOAD`; active request `A4HK906379`, target `DEV`, layer `ZDEV` |
| FLP / WebGUI | Yes | HTTPS | Serialized transaction `ZTOAD` resolves through both direct paths; exact `BASE-RUN-006` candidate proves the empty-editor/stream-input/ALV core mode and clean exit |
| UI5 repository | Yes | ADT | Not required for ZTOAD |
| AMDP debugging | No endpoint | — | Not required for ZTOAD |
| Text search | No | ICF disabled | Use object search/source reads instead |

The first request created during setup, `A4HK906377`, is an empty local request with no target and is not used by ZTOAD. It was deliberately left untouched rather than deleted automatically.

## Lint Configuration

- **ARC-1 preset**: `onprem`
- **ARC-1 system release**: SAP_BASIS 758; the pre-write local linter incorrectly selects `v702`, tracked as `BASE-TOOL-003`
- **ARC-1 rule inventory**: 158 enabled, 25 disabled
- **Repository gate**: pinned `@abaplint/cli` with the compatibility-focused rules in `abaplint.json`
- **Compatibility floor**: SAP_BASIS 750; the separate 7.50 system is still required for the authoritative downport gate
- **Full quality inventory**: 2,109 findings across 61 rules on exact merged master `5218476`; 2,169 across 63 rules on BASE-BUG-002; diagnostic only until the zero-findings plan is complete

## RAP Constraints Snapshot

- **RAP endpoint status**: available on SAP_BASIS 758, but not part of the ZTOAD architecture.
- **Recommended build mode**: not applicable; retain the classic report during incremental extraction.
- **TABL admin type guidance**: preserve the existing classic DDIC table so it remains compatible with SAP_BASIS 750.
- **Known projection BDEF caveat**: not applicable.
- **Known DDLX scope caveat**: not applicable.
- **Lint coverage hint**: lint the ABAP and abapGit XML locally; live syntax, ABAP Unit, ATC, activation, ST22, and UI smoke checks remain mandatory.
- **RAP helper path**: not applicable.

## Current ZTOAD Deployment

| Check | Result on A4H |
|---|---|
| Candidate branch / exact tested commit | `codex/fix-base-bug-001-npl` / source commit `9e8d881` |
| Package / transport | `ZTOAD` / `A4HK906379` |
| Repository objects | PROG `ZTOAD`, TABL `ZTOAD`, SUSO `ZTOAD_AUTH`, TRAN `ZTOAD` |
| Active/inactive state | Candidate main source was equal at server SHA-256 `c7d4cbcfcb9a3af1d322e3f912c586dfee12b8af0fe608049807cfa61e94cccd`; global inactive inventory contained no ZTOAD child part |
| SAP syntax | 0 errors; 2 pre-existing POSIX warnings |
| ABAP Unit | 67 passed, 0 failed |
| ATC `S4HANA_READINESS_2023` | 0 rows returned; non-authoritative because known prerequisites are unavailable |
| ATC `ABAP_CLOUD_READINESS` | Complete candidate run: 682 findings (474 P1, 208 P2); classic Dynpro/GUI design is not ABAP Cloud compatible |
| WebGUI smoke | Not rerun for the test-literal-only candidate; prior fresh editor/ALV/F3/ST22 evidence remains applicable because production and serialized UI objects are unchanged |
| Transaction launch | Standalone WebGUI and FLP `Shell-startGUI` intent both reach the complete ZTOAD transaction closure |
| Shared target after evidence | Restored and explicitly activated to `origin/master` `d532b2e`; active/inactive server SHA-256 `e32d7d3b8bebdb38457cd81f52e90a3b00dc0e830ac537b7690b70cee4544897`, 67/67 master Unit, no inactive ZTOAD part; native abapGit remained on `refs/heads/master` |

## Coding Guidance

- Target **SAP_BASIS 750 / ABAP 7.50** syntax and APIs unless the compatibility policy is explicitly changed.
- Treat A4H as the **SAP_BASIS 758** compile, ATC, ABAP Unit, and modern-runtime target.
- This application is classic Dynpro/Control Framework software. Clean-core Level A is not a realistic target without replacing the UI and execution architecture; the near-term on-premise target is Level B with internal/unsupported calls removed or isolated.
- Never infer browser compatibility from activation. WebGUI uses the tested TextEdit/ALV core capability profile; desktop keeps the complete ABAP-editor/tree/multi-tab workspace.
- Keep native SQL disabled by default. Any parser/executor change needs explicit authorization, injection, row-limit, and error-leakage tests.
- Use native abapGit for complete object round trips. ARC-1 remains preferred for reads, targeted source writes, activation, syntax, ABAP Unit, ATC, object state, and ST22 diagnostics.
- ARC-1 source writes must be followed by explicit activation and an object-state comparison. `activate=true` on the write request did not activate this candidate; the separate activation call did.
- ARC-1's native-abapGit bridge is installed and functional. Current gaps are client-side feature-cache, ref/postcondition, remote-auth diagnostics, large-source, and report-local edit ergonomics; no additional A4H component is indicated.

## Secondary Target: NPL / ABAP 7.50

| Field | Value |
|---|---|
| SID / client | NPL / 001 |
| Release | SAP_BASIS 750 SP02; SAP_ABA, SAP_UI, and SAP_GWFND 750 SP02 |
| Purpose | ADT-only minimum-release activation, syntax, ABAP Unit, ATC, and inactive-object gate |
| ARC-1 | Separate `arc-1-750` profile, pinned to ARC-1 1.0.2; package ceiling configured as `*`; data preview and free SQL disabled |
| UI boundary | No FLP, WebGUI, SAP GUI, or browser automation for validation; A4H owns UI smoke |
| ZTOAD state | Complete object set provisioned through native abapGit 1.134.0 offline repository in local package `$ZTOAD2`: PROG, real transparent TABL, TRAN, and SUSO |
| Structural state | BASE-DDIC-001 candidate is active as `#NOT_EXTENSIBLE`; all seven table fields are unchanged and the offline serializer warning is resolved |
| Completion status | Exact native candidate `4206a1a`: explicit table/report activation, syntax 0 errors, 67/67 Unit, complete `DEFAULT` ATC 88 unchanged findings (3 P1, 4 P2, 81 P3), and zero inactive ZTOAD parts |
| ARC-1 table-state caveat | Direct active `TABL` object-state returns 404 on this 7.50 endpoint; automatic and inactive-version reads resolve the active table and report no inactive draft. Explicit activation, exact metadata comparison, search, and the global inactive inventory are the compensating evidence. |

See [the NPL ADT-only validation dossier](docs/research/2026-08-06-npl-adt-only-validation.md) and the [BASE-BUG-001 grammar investigation](docs/research/2026-08-07-base-bug-001-npl-count-grammar.md). No stub DDIC structure may be used to claim compatibility.

## Verified A4H Access Paths

- FLP transaction intent: `${SAP_URL}/sap/bc/ui2/flp?sap-client=001#Shell-startGUI?sap-ui2-tcode=<TCODE>`
- Standalone WebGUI: `${SAP_URL}/sap/bc/gui/sap/its/webgui?sap-client=001&~transaction=<TCODE>`
- Do not use ports `50000` or `50001` from clients; only the HTTPS reverse proxy is supported.
