# ZTOAD TDD and test strategy

This document defines the permanent test discipline for ZTOAD. The current baseline is intentionally a working, characterized version with known defects; new work proceeds one finding at a time from `docs/baseline-findings.md`.

## Red–green–refactor through pull requests

`master` is the stable integration and release line. Each finding uses one short-lived branch and pull request; red states may exist locally or on the branch during development, but are never merged or pushed directly to `master`. The shared SAP native-abapGit repository remains linked to `master` for normal source-only work, so testing an unmerged source candidate must be recorded as a controlled direct deployment rather than a clean abapGit branch state.

For every bug or feature:

1. Research one finding, inspect dependencies and active/inactive state, and record a minimal sanitized reproduction.
2. Add one focused regression test, then replay the original implementation to prove it fails for the intended reason.
3. Write and review the implementation/live-test/rollback plan under `docs/plans/`.
4. Make the smallest production change that turns the test green.
5. Run the entire local and available live regression suite. Refactor only while it stays green; do not mix mass style cleanup with a behavior fix.
6. Perform a final diff/security review, update finding evidence, open the PR, and wait for CI.
7. After the first green run, audit the complete process and CI, improve the repository guidance in the same PR, move the plan to `docs/plans/finished/`, and wait for CI again.

## Test layers

| Layer | Purpose | Runs where | Required for |
|---|---|---|---|
| Local abaplint | Fast syntax floor, dependency/XML consistency, regression against configured rules | Developer machine and GitHub Actions | Every change |
| ABAP Unit | Pure parser/generator/policy behavior with no GUI or persistent data | SAP_BASIS 750 and 758 | Every production logic change |
| SAP syntax + activation | Authoritative compiler and repository consistency | Both SAP targets | Every `src/` change |
| ATC | Security, performance, released API, and migration checks | Both SAP targets | Every `src/` change |
| Native-abapGit check | Complete object serialization and remote/local consistency | Both SAP targets | Every structural/deployment change |
| Repository contract | Required cross-object launcher semantics not inferred by abaplint | Local and GitHub Actions | Every change |
| Integration test | DB/auth/executor behavior against disposable objects | Dedicated test client only | Parser/execution/security changes |
| WebGUI/FLP smoke | Startup, controls, basic read-only query, navigation | A4H only | UI/startup changes and release candidates |
| ST22/log check | Detect uncaught regressions even if the browser returns to SAP Easy Access | A4H | Every live browser smoke test |

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

NPL/SAP_BASIS 750 is ARC-1/ADT-only. Run activation, syntax, ABAP Unit, and ATC there; do not use FLP, WebGUI, SAP GUI, or browser automation. If a required object cannot be installed through the available ADT surface, record a blocked prerequisite rather than using an unfaithful substitute.

For A4H, use only the HTTPS reverse proxy:

- FLP: `https://a4h.marianzeis.de/sap/bc/ui2/flp?sap-client=001#Shell-startGUI?sap-ui2-tcode=<TCODE>`
- WebGUI: `https://a4h.marianzeis.de/sap/bc/gui/sap/its/webgui?sap-client=001&~transaction=<TCODE>`

Do not use ports 50000 or 50001. Credentials stay in the ignored `.env` file and must never appear in test output or screenshots.

Run this sequence after deployment:

1. Confirm native abapGit points at `master` and its check is clean.
2. Confirm no unrelated inactive divergence and record the exact candidate commit/source hash being tested.
3. Deploy and explicitly activate only the intended changed objects. Do not describe an unmerged directly deployed source as a native-abapGit `master` pull, and do not rely on a write request's activation option.
4. Confirm active and inactive source are identical, then run active SAP syntax.
5. Run all ABAP Unit tests; require zero failures.
6. Run the recorded ATC variants and inspect prerequisite/check errors. A result with missing prerequisites is incomplete even when no finding rows are displayed.
7. Record the latest ST22 dump timestamp before UI execution.
8. Verify the installed dynpro and GUI status required by the scenario, then launch ZTOAD in a fresh browser session and run only a read-only sanitized smoke query, initially `SELECT SINGLE mandt FROM t000`.
9. Verify expected UI/result state and confirm ST22 has no new dump.
10. Do not repeat the browser portion on NPL; repeat only the ADT activation/syntax/Unit/ATC gates there.

If FLP cannot open WebGUI because the automation browser blocks a popup, record that environmental failure and use the standalone HTTPS WebGUI URL as a secondary diagnostic path. Before interpreting a runtime failure, verify that the installed report contains the serialized dynpros and GUI statuses required by the test. Classify missing installation metadata separately from a product-code regression, but keep the overall smoke gate blocked until both are green.

For `BASE-RUN-001`, editor startup/render/input and the ST22 delta are green on A4H. `BASE-BUG-006` adds the serialized report transaction and proves both direct launch paths reach that editor. Query dispatch remains blocked because installed GUI status `STATUS010` is missing (`BASE-BUG-007`), despite being present in repository XML.

For GUI-control changes, a green policy Unit test proves only the selection decision. The chosen control remains a spike until a fresh live session renders it, the intended interaction works, and ST22 stays unchanged. If a spike merely moves the dump to another constructor or event path, reject it and update the root-cause model before implementation continues.

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
- the A4H read-only UI smoke suite passes with no new ST22 dump;
- the finding register and changelog/release metadata are updated.

An unavailable live system is a missing gate, not a pass. Record it and complete it before release unless the maintainer explicitly accepts the risk.
