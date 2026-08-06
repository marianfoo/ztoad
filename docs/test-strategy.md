# ZTOAD TDD and test strategy

This document defines the permanent test discipline for ZTOAD. The current baseline is intentionally a working, characterized version with known defects; new work proceeds one finding at a time from `docs/baseline-findings.md`.

## Red–green–refactor on `master`

The maintainer has selected `master` as the working branch for the current phase. Keep the Git working tree local while a test is red; do not push a known-red `master` state.

For every bug or feature:

1. Select one finding ID and record a minimal, sanitized reproduction.
2. Add one focused regression test that fails for the intended reason. Confirm the failure on the oldest available target.
3. Make the smallest production change that turns the test green.
4. Run the entire local and live regression suite.
5. Refactor only while the suite stays green; do not mix mass style cleanup with a behavior fix.
6. Update the finding status/evidence, then commit with a Conventional Commit subject.
7. Push `master` only after all required gates are green or an explicitly documented gate is unavailable.

If the project later enables multiple concurrent contributors, switch to short-lived branches and pull requests. Until that decision changes, native abapGit repositories remain on `master` and only one person should own the live package at a time.

## Test layers

| Layer | Purpose | Runs where | Required for |
|---|---|---|---|
| Local abaplint | Fast syntax floor, dependency/XML consistency, regression against configured rules | Developer machine and GitHub Actions | Every change |
| ABAP Unit | Pure parser/generator/policy behavior with no GUI or persistent data | SAP_BASIS 750 and 758 | Every production logic change |
| SAP syntax + activation | Authoritative compiler and repository consistency | Both SAP targets | Every `src/` change |
| ATC | Security, performance, released API, and migration checks | Both SAP targets | Every `src/` change |
| Native-abapGit check | Complete object serialization and remote/local consistency | Both SAP targets | Every structural/deployment change |
| Integration test | DB/auth/executor behavior against disposable objects | Dedicated test client only | Parser/execution/security changes |
| WebGUI/FLP smoke | Startup, controls, basic read-only query, navigation | A4H and later 7.50 if supported | UI/startup changes and release candidates |
| ST22/log check | Detect uncaught regressions even if the browser returns to SAP Easy Access | Both SAP targets | Every live smoke test |

## Unit-test design rules

- Test names state behavior, not implementation.
- Use Arrange–Act–Assert with one primary action and focused assertions.
- Declare report tests `FOR TESTING RISK LEVEL HARMLESS DURATION SHORT` at the end of the report.
- Prefer pure data-in/data-out classes. Existing `FORM` tests are a temporary characterization bridge.
- Do not access frontend controls, user files, business data, commits, or persistent customizing from ABAP Unit.
- Inject authorization, database, editor, generator, and executor collaborators through narrow interfaces as each path is changed.
- Test valid, invalid, boundary, and hostile input. ZTOAD's parser is an authorization and injection boundary, not only a formatter.
- Never weaken a test merely to accommodate current behavior. If the current behavior is deliberately preserved, document why in the finding.

## Parser regression matrix

Each parser/generator change should select relevant cases from this matrix:

| Area | Required cases |
|---|---|
| Lexing | upper/lower case, tabs/multiple spaces, multiline input, comments, escaped quotes, quoted dots/keywords |
| Select list | simple fields, qualified fields, aliases, `*`, aggregate, nested function, nested `CASE`, comma and old syntax |
| Sources | one table, alias, multiple joins, subquery, nested subquery, UNION branch, unauthorized inner table |
| Clauses | WHERE, GROUP BY, HAVING, ORDER BY, UP TO, INTO/APPENDING, strict-syntax ordering |
| Set operations | UNION, UNION ALL, branch layout mismatch, limits/order in branches |
| Limits | default, explicit positive, zero/unlimited, invalid/overflow, policy maximum |
| DML | INSERT values/set, UPDATE, DELETE, conversion errors, authorization denial; disposable Z table only |
| Native SQL | disabled default, authorization denial, strict allow list, unsupported operation rejection; never business data |
| Error handling | parse rejection, compile rejection, runtime exception, sanitized message, no unexpected ST22 dump |

## Live test protocol

For A4H, use only the HTTPS reverse proxy:

- FLP: `https://a4h.marianzeis.de/sap/bc/ui2/flp?sap-client=001#Shell-startGUI?sap-ui2-tcode=<TCODE>`
- WebGUI: `https://a4h.marianzeis.de/sap/bc/gui/sap/its/webgui?sap-client=001&~transaction=<TCODE>`

Do not use ports 50000 or 50001. Credentials stay in the ignored `.env` file and must never appear in test output or screenshots.

Run this sequence after deployment:

1. Confirm native abapGit points at `master` and its check is clean.
2. Confirm no inactive divergence.
3. Activate all changed objects.
4. Run SAP syntax.
5. Run all ABAP Unit tests; require zero failures.
6. Run the recorded ATC variants.
7. Record the latest ST22 dump timestamp before UI execution.
8. Launch ZTOAD and run only a read-only sanitized smoke query, initially `SELECT SINGLE mandt FROM t000`.
9. Verify expected UI/result state and confirm ST22 has no new dump.
10. Repeat on the other SAP target.

`BASE-RUN-001` currently blocks steps 8–9 in WebGUI because `CL_GUI_ABAPEDIT` dumps. Until fixed, unit/syntax/ATC checks remain valid, but browser end-to-end status is failed rather than skipped.

## Database-writing integration tests

No normal smoke or unit test may modify SAP or business tables. A test of INSERT/UPDATE/DELETE/native behavior requires all of the following:

- an explicitly disposable Z table in the test package;
- a dedicated test user/role with no broad wildcard access;
- fixtures with no personal or confidential data;
- unique test keys so parallel/previous runs cannot collide;
- cleanup in `teardown` or a verified finally-style path;
- a pre-test and post-test row-count assertion;
- a recovery procedure if cleanup fails.

Native SQL remains disabled unless the test specifically targets its replacement/security policy and has explicit maintainer approval.

## Release acceptance

A release candidate is accepted only when:

- `npm ci && npm test` is green;
- native abapGit serialization is reviewed and clean;
- SAP_BASIS 750 and A4H 758 activate and pass syntax;
- all ABAP Unit tests pass on both systems;
- the selected ATC variants have no new unapproved finding;
- the read-only UI smoke suite passes with no new ST22 dump;
- the finding register and changelog/release metadata are updated.

An unavailable live system is a missing gate, not a pass. Record it and complete it before release unless the maintainer explicitly accepts the risk.
