# Development setup: decisions and open choices

_Prepared 2026-08-06 from repository inspection, open GitHub issues, SAP Docs MCP results, abapGit documentation, abaplint documentation, and Release Please documentation._

## Implemented because the recommendation is clear

| Decision | Evaluation |
|---|---|
| Treat ABAP 7.50 as the compatibility floor | It is the oldest requested live target. Local parsing must reject accidental use of newer syntax before a SAP pull. |
| Validate again on S/4HANA 2023 | Newer parser/runtime behavior can differ even when 7.50 activation succeeds. |
| Use native abapGit for round trips | ZTOAD includes screens and XML-based objects. ARC-1's source mirror explicitly does not provide a complete metadata round trip. |
| Keep Git as released source of truth | It gives one auditable line from issue to diff to release; system-only changes must be exported before completion. |
| Pin abaplint exactly | abaplint states that it does not currently follow semantic versioning and recommends a fixed version. |
| Start with a zero-warning syntax/XML baseline | Enabling a full modern style profile on a legacy 5,000-line report would hide new failures in old noise. Rules can become stricter alongside focused refactors. |
| Require local plus live checks | abaplint cannot execute ABAP, activate repository objects, run ABAP Unit, or prove ATC/authorization behavior. |
| Require harmless, short ABAP Unit tests | SAP's test properties make execution safety and duration explicit; this is appropriate for routine development gates. |
| Use Release Please manifest mode | It records the existing 4.0.4 version, avoids replaying unrelated history, preserves current unprefixed tags, and can synchronize arbitrary annotated files. |
| Add structured issue and PR templates | Existing issues often omit exact release/support-package/test-matrix data. The templates collect the evidence needed to reproduce parser differences. |

## Decisions that need maintainer input

### 1. Exact ATC variant on ABAP 7.50

A4H is now verified: `S4HANA_READINESS_2023` reports 0 findings and `ABAP_CLOUD_READINESS` reports 758 findings. The latter proves the classic report is not ABAP Cloud compatible and is retained as an architectural burn-down signal, not a zero gate.

The matching SAP_BASIS 750 variant remains open because that destination is not configured. Recommendation: inventory the available 7.50 variants, select the closest effective security/performance/syntax set, and document differences rather than assuming identical names mean identical checks.

### 2. Package and transport model

Decision implemented on A4H: transportable package `ZTOAD`, transport layer `ZDEV`, request `A4HK906379`, target `DEV`. This makes ATC/package checks meaningful and leaves an auditable CTS record.

The ABAP 7.50 package remains open until its landscape is connected. Prefer an equivalent transportable package if it belongs to the same governed landscape; otherwise a local sandbox package is acceptable when the difference is recorded.

### 3. Automated live-system CI

Recommendation: keep live checks manual/ARC-1-assisted for now. Add automation only on a trusted self-hosted runner with a dedicated least-privilege SAP technical user, protected environment secrets, concurrency one per system, and cleanup/rollback controls.

Trade-off: live CI improves repeatability but creates credential, network, system-load, and destructive-test risk. GitHub-hosted runners should not receive broad SAP credentials.

### 4. Release Please authentication

Implemented default: repository `GITHUB_TOKEN`, with explicit action permissions.

Potential change: a fine-grained PAT or GitHub App token if release-PR creation must trigger other workflows automatically. GitHub suppresses some workflow cascades created by `GITHUB_TOKEN`; a stronger token adds secret lifecycle and privilege-management work.

### 5. Branch concurrency inside SAP

Current decision: stay on `master`, keep red/incomplete work local, and allow one owner for package `ZTOAD` at a time. Native abapGit repository `000000000017` is linked to `master`.

Alternative for later: short-lived branches and pull requests when concurrent contributors are needed. abapGit Flow can map filtered Git operations to transports, but its documentation marks it beta, so it is not enabled.

### 6. Minimum release in `.abapgit.xml`

Recommendation: after successful installation on the actual 7.50 system, consider recording a SAP_BASIS 750 requirement through native abapGit Repository Settings.

Why it is open: adding it can intentionally block older systems that may still run the historical program. The support policy should be confirmed before changing install behavior, and abapGit recommends editing these settings through its UI.

### 7. Scope of the legacy refactor

Recommendation: extract query parser/generator units issue by issue, beginning with a regression-test harness for issues #4, #6, and #7. Avoid a big-bang rewrite of the report and GUI.

Alternative: a full OO rewrite could improve design faster but greatly expands regression risk and makes cross-release comparison harder.

### 8. Historical `4.0.4` tag

Current code and documentation identify version `4.0.4`, but Git contains only the `4.0.3` tag. The Release Please manifest therefore starts at the declared code version `4.0.4` and correctly proposes `4.0.5` for the next fix, but its first generated compare link assumes that a `4.0.4` tag exists.

Recommendation: after the current `master` state has passed both live-system gates, create a one-time `4.0.4` tag and GitHub Release at the exact verified commit. Do not backfill it before live verification, and do not move the tag later.

## Open-issue orientation for the next phase

| Issue | Setup implication | Suggested first move |
|---|---|---|
| #4 Open SQL functions | `SUBSTRING`/`CONCAT` are ABAP 7.50 SQL features and expose tokenizer assumptions. | Add the focused failing nested-function test described by `BASE-BUG-003`. |
| #6 `INTO/APPENDING` placement | ABAP 7.50 strict mode requires `INTO` at the end for affected new-syntax statements. | Capture the exact generated source on both systems and test clause ordering. |
| #7 `CASE` in aggregate | Nested SQL expressions are being interpreted as result components. | Add an aggregate-with-CASE regression test and isolate select-list parsing. |
| #2 Transaction code | Requires a serialized `TRAN` object, not only source. | Create it in SAP, export through native abapGit, and validate on both systems. |
| #5 Manual installation | Source-only copying is incomplete because the report has dynpros/table/auth metadata. | Native-abapGit installation is now verified; document the WebGUI startup defect separately from installation. |

The setup also discovered `BASE-RUN-001`: WebGUI/FLP startup dumps in `CL_GUI_ABAPEDIT`. See [baseline-findings.md](baseline-findings.md) for the complete ordered register and evidence. No existing GitHub issue was closed and no production bug fix was made during baseline characterization.
