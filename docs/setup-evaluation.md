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

A4H currently has an incomplete `S4HANA_READINESS_2023` run: no finding rows were returned, but seven prerequisite checks are unavailable. On the BASE-RUN-001 candidate, `ABAP_CLOUD_READINESS` reports 768 findings (463 P1, 305 P2). Earlier 758/767 results remain historical evidence. The Cloud variant proves the classic report is not ABAP Cloud compatible and is retained as an architectural burn-down signal, not a zero gate.

The matching SAP_BASIS 750 variant remains open because that destination is not configured. Recommendation: inventory the available 7.50 variants, select the closest effective security/performance/syntax set, and document differences rather than assuming identical names mean identical checks.

### 2. Package and transport model

Decision implemented on A4H: transportable package `ZTOAD`, transport layer `ZDEV`, request `A4HK906379`, target `DEV`. This makes ATC/package checks meaningful and leaves an auditable CTS record.

The ABAP 7.50 package remains open until its landscape is connected. Prefer an equivalent transportable package if it belongs to the same governed landscape; otherwise a local sandbox package is acceptable when the difference is recorded.

### 3. Automated live-system CI

Recommendation: keep live checks manual/ARC-1-assisted for now. Add automation only on a trusted self-hosted runner with a dedicated least-privilege SAP technical user, protected environment secrets, concurrency one per system, and cleanup/rollback controls.

Trade-off: live CI improves repeatability but creates credential, network, system-load, and destructive-test risk. GitHub-hosted runners should not receive broad SAP credentials.

### 4. Release Please authentication

Implemented default: repository `GITHUB_TOKEN`, with explicit action permissions. Release Please successfully created PR #10 for version 4.1.0. Its repository Quality run entered GitHub's approval-required state; after manual approval it passed and the PR became cleanly mergeable. This is the expected least-privilege operating mode, not a CI failure.

Potential change: a dedicated GitHub App installation token or fine-grained PAT if release-PR workflows must run without manual approval. Prefer an App for scoped, short-lived credentials. Either option adds credential lifecycle and privilege-management work, so it is not introduced by a source bug PR. See GitHub's [`GITHUB_TOKEN` trigger behavior](https://docs.github.com/en/actions/concepts/security/github_token#when-github_token-triggers-workflow-runs).

### 5. Branch concurrency inside SAP

Current decision: keep `master` as the only long-lived integration/release branch and keep native abapGit repository `000000000017` linked to it. Develop each finding on a short-lived pull-request branch. For source-only candidates, deploy the exact source directly and record the candidate commit instead of switching the shared SAP repository branch.

Structural-object branches need a dedicated package/system or an explicitly coordinated branch switch because native abapGit changes the real system objects. abapGit Flow can map filtered Git operations to transports, but its documentation marks it beta, so it is not enabled.

### 6. Minimum release in `.abapgit.xml`

Recommendation: after successful installation on the actual 7.50 system, consider recording a SAP_BASIS 750 requirement through native abapGit Repository Settings.

Why it is open: adding it can intentionally block older systems that may still run the historical program. The support policy should be confirmed before changing install behavior, and abapGit recommends editing these settings through its UI.

### 7. Scope of the legacy refactor

Recommendation: extract query parser/generator units issue by issue, beginning with a regression-test harness for issues #4, #6, and #7. Avoid a big-bang rewrite of the report and GUI.

Alternative: a full OO rewrite could improve design faster but greatly expands regression risk and makes cross-release comparison harder.

### 8. Historical `4.0.4` tag

Current code and documentation identify version `4.0.4`, but Git contains only the `4.0.3` tag. The Release Please manifest starts at the declared code version `4.0.4`; current PR #10 correctly proposes `4.1.0` because the accumulated conventional commits include a feature. Its first generated compare link still assumes that a `4.0.4` tag exists.

Recommendation: after the current `master` state has passed both live-system gates, create a one-time `4.0.4` tag and GitHub Release at the exact verified commit. Do not backfill it before live verification, and do not move the tag later.

### 9. Protecting `master`

The GitHub API currently reports that `master` is not protected. Recommendation: after the pull-request workflow has been used successfully, require pull requests and the `abaplint (ABAP 7.50)` Quality check, block force pushes/deletion, and decide whether maintainer approval is required for a single-maintainer repository.

This is not changed automatically in the bug PR because repository rules are external policy, can lock out emergency maintenance if configured incorrectly, and need the maintainer's explicit approval.

### 10. ABAP 7.02 distribution

Recommendation: keep the current SAP_BASIS 750 support floor and one canonical codebase. Do not create a hand-maintained second branch. A generated 7.02 artifact becomes reasonable only with a live 7.02 system and a deterministic activation/unit/ATC/smoke matrix. See the [7.02/downport research](research/2026-08-06-abap-702-and-abaplint-downport.md).

### 11. Test and manual-installation packaging

Recommendation: retain report-local tests until parser/generator areas are extracted to global classes; abapGit can then serialize class test includes separately. Do not add an arbitrary second test report. A later generated source-only artifact may help manual users, but native abapGit remains the supported complete installation because ZTOAD needs screens, table, authorization, and transaction metadata. See the [test-packaging research](research/2026-08-06-abap-unit-test-packaging.md).

### 12. Full abaplint gate

The pinned local default inventory is 1,857 findings across 57 rules. `npm run lint:quality` now reproduces it without making every PR red. Recommendation: burn the list down in correctness/architecture/mechanical phases and add `npm run lint:quality -- --strict` to required CI only when it reaches zero. See the [research](research/2026-08-06-abaplint-quality-roadmap.md) and [active plan](plans/abaplint-zero-findings.md).

## Open-issue orientation for the next phase

| Issue | Setup implication | Suggested first move |
|---|---|---|
| #4 Open SQL functions | `SUBSTRING`/`CONCAT` are ABAP 7.50 SQL features and expose tokenizer assumptions. | Add the focused failing nested-function test described by `BASE-BUG-003`. |
| #6 `INTO/APPENDING` placement | Fixed with strict/legacy generator branches and three generator tests; 17/17 pass on A4H. | Complete the missing live SAP_BASIS 750 gate before release acceptance. |
| #7 `CASE` in aggregate | Nested SQL expressions are being interpreted as result components. | Add an aggregate-with-CASE regression test and isolate select-list parsing. |
| #2 Transaction code | Requires a serialized `TRAN` object, not only source. | Create it in SAP, export through native abapGit, and validate on both systems. |
| #5 Manual installation | Source-only copying is incomplete because the report has dynpros/table/auth metadata. | Native-abapGit installation and inactive-child closure are now verified; query execution failures remain separate runtime findings. |

The setup also discovered `BASE-RUN-001`: WebGUI startup dumped in `CL_GUI_ABAPEDIT`. The later BASE-RUN-001 candidate fixes editor startup/render/input. `BASE-BUG-007` restores the complete active program metadata, so dispatch now reaches `EXECUTE`; the resulting `SAPLOLEA` Control Framework flush dump is independently tracked as `BASE-RUN-006`. See [baseline-findings.md](baseline-findings.md) for the complete ordered register and current evidence. No existing GitHub issue was closed during the original baseline characterization.
