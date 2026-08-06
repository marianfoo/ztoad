# ZTOAD repository instructions

These rules apply to every change in this repository. Read [docs/development.md](docs/development.md), [docs/test-strategy.md](docs/test-strategy.md), and [docs/baseline-findings.md](docs/baseline-findings.md) before changing ABAP objects or deployment metadata, and read [system-info.md](system-info.md) before using a live SAP system.

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

1. Stay on `master` while that remains the maintainer-selected workflow. Keep a red test or incomplete fix local and never push a known-red `master` state.
2. Start from a clean native-abapGit status in each system used for testing and identify one finding/issue.
3. Reproduce it with sanitized inputs and record the affected system release.
4. Add the smallest failing regression test first and confirm it fails for the intended reason.
5. For an existing object, inspect dependencies and active/inactive state before editing. Prefer ARC-1 context/read operations when available.
6. Edit ABAP source locally when the change is source-only. Create or structurally change SAP objects in a development system, then export them with native abapGit; do not invent serializer XML by hand.
7. Make the smallest production change that turns the test green, then refactor only while the full suite stays green.
8. Run `npm ci` and `npm test` locally.
9. Deploy/pull `master` into the ABAP 7.50 test system first. Require deserialization, activation, syntax, ABAP Unit, ATC, safe manual smoke, and no new ST22 dump.
10. Repeat the same checks on S/4HANA 2023.
11. Export any system-side correction through native abapGit, pull it locally, and review the complete diff before committing.
12. Commit with a Conventional Commit subject. `fix:` creates a patch release, `feat:` a minor release, and a `!`/`BREAKING CHANGE` a major release.

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

## Files and release automation

- Keep abapGit object files under `src/`; root documentation and CI files are outside `.abapgit.xml`'s `/src/` starting folder.
- Preserve lower-case abapGit filenames and LF line endings.
- Do not reformat the legacy report as part of an unrelated fix.
- Release Please owns `CHANGELOG.md`, `version.txt`, and the annotated version lines in `README.md` and `src/ztoad.prog.abap` after bootstrap.
- Do not manually tag ordinary releases. Merge the Release Please PR after its checks and version diff are reviewed.
