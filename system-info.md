# System Info: A4H / ZTOAD test matrix

_Updated: 2026-08-06_ · _Source: live ARC-1 discovery on A4H and NPL, native abapGit, SAP syntax/Unit/ATC runs, and A4H WebGUI smoke testing_

## Identity

| Field | Value |
|---|---|
| SID | A4H |
| System type | on-premise S/4HANA |
| Release | ABAP Platform 2023 / SAP_BASIS 758 SP02 |
| Kernel | Not reported by the available ADT discovery endpoints |
| Host | `https://a4h.marianzeis.de` (HTTPS reverse proxy; no SAP port suffix) |
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
| abapGit | Yes | native, online | `ZABAPGIT` 1.133.0; ZTOAD repository key `000000000017`, package `ZTOAD`, branch `master` |
| gCTS | Endpoint available | no ZTOAD repository | Native abapGit remains the selected round-trip mechanism |
| Transports | Yes | CTS | Transportable package `ZTOAD`; active request `A4HK906379`, target `DEV`, layer `ZDEV` |
| FLP / WebGUI | Yes | HTTPS | WebGUI starts, but ZTOAD currently dumps while constructing `CL_GUI_ABAPEDIT`; see `BASE-RUN-001` |
| UI5 repository | Yes | ADT | Not required for ZTOAD |
| AMDP debugging | No endpoint | — | Not required for ZTOAD |
| Text search | No | ICF disabled | Use object search/source reads instead |

The first request created during setup, `A4HK906377`, is an empty local request with no target and is not used by ZTOAD. It was deliberately left untouched rather than deleted automatically.

## Lint Configuration

- **ARC-1 preset**: `onprem`
- **ARC-1 ABAP version**: `v758`
- **ARC-1 rule inventory**: 158 enabled, 25 disabled
- **Repository gate**: pinned `@abaplint/cli` with the compatibility-focused rules in `abaplint.json`
- **Compatibility floor**: SAP_BASIS 750; the separate 7.50 system is still required for the authoritative downport gate
- **Baseline full-rule audit**: 1,857 findings across 57 rules on `master`; BASE-RUN-001 candidate 1,878 with 21 explained adapter diagnostics

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
| Git branch / remote commit imported | `master` / `cae4dea2062b` |
| Package / transport | `ZTOAD` / `A4HK906379` |
| Repository objects | PROG `ZTOAD`, TABL `ZTOAD`, SUSO `ZTOAD_AUTH` |
| Active/inactive source | Identical; no inactive divergence |
| SAP syntax | 0 errors; 4 warnings |
| ABAP Unit | 19 passed, 0 failed |
| ATC `S4HANA_READINESS_2023` | 0 rows returned; non-authoritative because known prerequisites are unavailable |
| ATC `ABAP_CLOUD_READINESS` | 768 findings (463 P1, 305 P2); classic Dynpro/GUI design is not ABAP Cloud compatible |
| WebGUI smoke | Fresh final launch renders the plain text editor and accepts `SELECT SINGLE mandt FROM t000`; no new ST22 dump |
| Remaining UI prerequisite | A4H installation lacks GUI status `STATUS010`, so query dispatch is blocked by `BASE-BUG-007` |

## Coding Guidance

- Target **SAP_BASIS 750 / ABAP 7.50** syntax and APIs unless the compatibility policy is explicitly changed.
- Treat A4H as the **SAP_BASIS 758** compile, ATC, ABAP Unit, and modern-runtime target.
- This application is classic Dynpro/Control Framework software. Clean-core Level A is not a realistic target without replacing the UI and execution architecture; the near-term on-premise target is Level B with internal/unsupported calls removed or isolated.
- Never infer browser compatibility from activation. The current `CL_GUI_ABAPEDIT` path is proven to dump in WebGUI and needs a tested fallback or replacement.
- Keep native SQL disabled by default. Any parser/executor change needs explicit authorization, injection, row-limit, and error-leakage tests.
- Use native abapGit for complete object round trips. ARC-1 remains preferred for reads, targeted source writes, activation, syntax, ABAP Unit, ATC, object state, and ST22 diagnostics.
- ARC-1 source writes must be followed by explicit activation and an object-state comparison. `activate=true` on the write request did not activate this candidate; the separate activation call did.

## Secondary Target: NPL / ABAP 7.50

| Field | Value |
|---|---|
| SID / client | NPL / 001 |
| Release | SAP_BASIS 750 SP02; SAP_ABA, SAP_UI, and SAP_GWFND 750 SP02 |
| Purpose | ADT-only minimum-release activation, syntax, ABAP Unit, and ATC gate |
| ARC-1 | Separate `arc-1-750` profile, pinned to ARC-1 1.0.2; write/activate/syntax/Unit/cleanup lifecycle proven |
| UI boundary | No FLP, WebGUI, SAP GUI, or browser automation; A4H owns UI smoke |
| ZTOAD state | Program and transparent table are absent |
| Blocking prerequisite | SAP_BASIS 750 exposes no ADT transparent-table create endpoint, so table `ZTOAD` cannot be safely provisioned through ARC-1 |
| Completion status | Connection usable; exact ZTOAD activation/syntax/Unit/ATC blocked until the real table exists |

See [the NPL ADT-only validation dossier](docs/research/2026-08-06-npl-adt-only-validation.md). A disposable report was created, activated, syntax-checked, unit-tested successfully, deleted, and confirmed absent. No stub DDIC structure may be used to claim compatibility.

## Verified A4H Access Paths

- FLP transaction intent: `https://a4h.marianzeis.de/sap/bc/ui2/flp?sap-client=001#Shell-startGUI?sap-ui2-tcode=<TCODE>`
- Standalone WebGUI: `https://a4h.marianzeis.de/sap/bc/gui/sap/its/webgui?sap-client=001&~transaction=<TCODE>`
- Do not use ports `50000` or `50001` from clients; only the HTTPS reverse proxy is supported.
