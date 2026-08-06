# ZTOAD repository instructions

These rules apply to every change in this repository. Read [docs/development.md](docs/development.md), [docs/test-strategy.md](docs/test-strategy.md), and [docs/baseline-findings.md](docs/baseline-findings.md) before changing ABAP objects or deployment metadata, and read [system-info.md](system-info.md) before using a live SAP system. Issue plans live in `docs/plans/`; move completed plans to `docs/plans/finished/`. Put dated investigations and external-source notes in `docs/research/`.

## Sources of truth

- GitHub `master` is the source of truth for released source and abapGit serialization.
- Native abapGit is the source of truth for round-tripping complete SAP repository objects, including metadata XML, screens, text elements, authorization objects, tables, and transactions.
- The ABAP 7.50 and S/4HANA 2023 systems are validation targets. Never treat an unexported system change as complete.
- ARC-1 is the preferred interface for system context, focused object reads, syntax checks, ABAP Unit, and ATC. A source-only ARC-1 mirror is useful for inspection but is not a complete abapGit deployment.

## Compatibility contract

- The minimum supported language/runtime target is on-premise SAP_BASIS 750 (ABAP 7.50).
- Every production ABAP or repository-object change must also be validated on S/4HANA 2023. Documentation/tooling-only changes may mark the live gates not applicable with a reason.
- Do not introduce syntax or APIs newer than the 7.50 floor unless the issue explicitly changes compatibility and the decision is documented.
- The local abaplint release identifier `v762` is its canonical mapping for on-premise SAP_BASIS 750; it does not mean that ZTOAD requires SAP_BASIS 762.

## Required workflow

For changes that affect `src/` or live behavior:

1. Start a short-lived `codex/<finding-id>` branch from current `master`. `master` remains the stable integration/release branch; never push a red or incomplete state to it. Keep the shared native-abapGit repository on `master` unless a structural-object test has an explicitly coordinated branch procedure.
2. Start from a clean native-abapGit/system state, select one finding, research the issue and dependencies, reproduce it with sanitized inputs, and identify the root cause. Verify that every permanent test fixture exists on all claimed target releases.
3. Add the smallest failing regression test and replay it against the original production code so the intended red failure is recorded.
4. Write an implementation/test/rollback plan in `docs/plans/`, including ABAP 7.50 compatibility, Clean ABAP/Clean Core, abaplint, ABAP Unit, live activation/syntax/ATC, safe browser smoke, and ST22 delta. Review the plan before production changes.
5. Implement the smallest change that turns the test green. Refactor only while the complete suite remains green. Edit source locally for source-only changes; create structural SAP objects in a development system and export them with native abapGit instead of inventing serializer XML.
6. Run `npm ci`, `npm test`, `git diff --check`, a complete diff review, and the relevant security/authorization review. Deploy the exact candidate to each available SAP target without pretending that the shared abapGit `master` link represents an unmerged branch.
7. On SAP_BASIS 750 first when available, then S/4HANA 2023, require controlled activation, active syntax, all ABAP Unit tests, complete ATC runs or explicit prerequisite failures, safe smoke, and ST22 delta. A failed/unavailable gate is never a pass.
8. Perform a final implementation review, update finding evidence, commit with a Conventional Commit subject, push the branch, open a pull request, and wait for required CI to become green.
9. After the first green PR run, audit the plan, implementation, test evidence, CI output, and development process. Apply useful process/documentation improvements to the same PR, move its plan to `docs/plans/finished/`, push, and wait for CI again.
10. Merge only after the maintainer accepts any recorded live-system limitations. Pull the resulting `master`, verify Release Please behavior, and do not manually tag an ordinary release.

For a source-only candidate, a controlled direct source deployment is preferable to switching the shared native-abapGit repository away from `master`. Record the candidate commit/hash and activate only the intended object. Structural changes still require a real native-abapGit round trip and may need a dedicated package/system to avoid changing shared objects underneath other work.

If ARC-1 authentication or a live system is unavailable, local checks may continue, but do not claim live validation. Record the missing gate in the PR and complete it before merge unless the maintainer explicitly accepts the risk.

## Testing rules

- New or changed non-GUI logic requires ABAP Unit coverage whenever technically feasible.
- Follow red–green–refactor: reproduce and make a focused test fail before changing production behavior.
- Existing open defects belong in the findings register; do not keep permanently failing or disabled regression tests on `master`.
- Put report test classes at the end of the program and declare them `FOR TESTING RISK LEVEL HARMLESS DURATION SHORT`.
- Prefer data-in/data-out parser and generator units with no database commits, user-specific state, frontend GUI, or persistent fixtures.
- Extract testable logic behind small local classes instead of adding more behavior to large `FORM` routines.
- Use dependency injection for external collaborators. Use test seams only as a temporary legacy-code bridge.
- Test both the success path and invalid/untrusted input. ZTOAD executes dynamic SQL, so authorization boundaries, dynamic table/column input, escaping, DML, and native SQL are security-sensitive.
- ABAP Unit tests must not change customizing or persistent business data. Any integration test that writes must use an explicitly disposable Z table and be cleaned up.
- Local abaplint is a fast compatibility/static gate, not a substitute for SAP syntax, activation, ABAP Unit, or ATC.

## Live-system safety

- Default smoke tests to read-only `SELECT` statements against non-sensitive test data.
- Never use production data, credentials, personal data, or confidential query text in issues, commits, CI logs, or test fixtures.
- Do not enable or broaden INSERT, UPDATE, DELETE, native SQL, or authorization defaults as part of an unrelated change.
- Do not run destructive SQL merely to prove parsing. DML/native tests require an isolated table, explicit authorization, and a cleanup plan.
- Resolve and record the ATC variant used on each system. Prefer the same effective checks on both systems.
- Record whether an ATC run was complete. Zero displayed findings with missing prerequisite checks is incomplete, not a pass.

## Files and release automation

- Keep abapGit object files under `src/`; root documentation and CI files are outside `.abapgit.xml`'s `/src/` starting folder.
- Keep active plans under `docs/plans/`, completed plans under `docs/plans/finished/`, and dated research under `docs/research/`.
- Preserve lower-case abapGit filenames and LF line endings.
- Do not reformat the legacy report as part of an unrelated fix.
- Release Please owns `CHANGELOG.md`, `version.txt`, and the annotated version lines in `README.md` and `src/ztoad.prog.abap` after bootstrap.
- Do not manually tag ordinary releases. Merge the Release Please PR after its checks and version diff are reviewed.
