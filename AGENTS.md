# ZTOAD repository instructions

These rules apply to every change in this repository. Read [docs/development.md](docs/development.md), [docs/test-strategy.md](docs/test-strategy.md), and [docs/baseline-findings.md](docs/baseline-findings.md) before changing ABAP objects or deployment metadata, and read [system-info.md](system-info.md) before using a live SAP system. Issue plans live in `docs/plans/`; move completed plans to `docs/plans/finished/`. Put dated investigations and external-source notes in `docs/research/`.

## Sources of truth

- GitHub `master` is the source of truth for released source and abapGit serialization.
- Native abapGit is the source of truth for round-tripping complete SAP repository objects, including metadata XML, screens, text elements, authorization objects, tables, and transactions.
- The ABAP 7.50 and S/4HANA 2023 systems are validation targets. Never treat an unexported system change as complete.
- ARC-1 is the preferred interface for system context, focused object reads, syntax checks, ABAP Unit, and ATC. A source-only ARC-1 mirror is useful for inspection but is not a complete abapGit deployment.
- NPL/SAP_BASIS 750 is an ARC-1/ADT-only target. Do not use FLP, WebGUI, SAP GUI, or browser automation there. UI/browser smoke belongs to A4H/SAP_BASIS 758.

## Compatibility contract

- The minimum supported language/runtime target is on-premise SAP_BASIS 750 (ABAP 7.50).
- Every production ABAP or repository-object change must also be validated on S/4HANA 2023. Documentation/tooling-only changes may mark the live gates not applicable with a reason.
- Do not introduce syntax or APIs newer than the 7.50 floor unless the issue explicitly changes compatibility and the decision is documented.
- The local abaplint release identifier `v762` is its canonical mapping for on-premise SAP_BASIS 750; it does not mean that ZTOAD requires SAP_BASIS 762.

## Required workflow

For changes that affect `src/` or live behavior:

1. Start a short-lived `codex/<finding-id>` branch from current `master`. `master` remains the stable integration/release branch; never push a red or incomplete state to it. Keep the shared native-abapGit repository on `master` unless a structural-object test has an explicitly coordinated branch procedure.
2. Start from a clean native-abapGit/system state, select one finding, research the issue and dependencies, reproduce it with sanitized inputs, and identify the root cause. Verify that every permanent test fixture and every serialized UI prerequisite needed by the smoke test exists on all claimed target releases.
3. Add the smallest failing regression test and replay it against the original production code so the intended red failure is recorded.
4. Write an implementation/test/rollback plan in `docs/plans/`, including ABAP 7.50 compatibility, Clean ABAP/Clean Core, abaplint, ABAP Unit, live activation/syntax/ATC, safe browser smoke, and ST22 delta. For security findings, distinguish demonstrated sink behavior from proven end-to-end entry-point reachability and state the actor prerequisites plus invariant without overclaiming. Review the plan before production changes.
5. Implement the smallest change that turns the test green. Refactor only while the complete suite remains green. For frontend, database, authorization, or other environment-dependent assumptions, treat the first green implementation as a spike until a live integration test confirms it. Edit source locally for source-only changes; create structural SAP objects in a development system and export them with native abapGit instead of inventing serializer XML.
6. Run `npm ci`, `npm test`, `git diff --check`, a complete diff review, and the relevant security/authorization review. Freeze the source/repository-object candidate in a commit before expensive live validation and record its commit plus source hash. Any subsequent `src/` or serialized-object change invalidates syntax, Unit, ATC, and smoke evidence and requires those affected gates to be rerun. Deploy the exact candidate to each available SAP target without pretending that the shared abapGit `master` link represents an unmerged branch.
7. On SAP_BASIS 750 first when available, then S/4HANA 2023, require controlled activation, active syntax, all ABAP Unit tests, and complete ATC runs or explicit prerequisite failures. An ARC-1 write acknowledgement or `activate=true` request is not activation evidence: call activation explicitly, require active/inactive main-object equality, and query inactive child parts (including screens, GUI statuses, text elements, and includes) for every changed composite object. Main-source equality alone is not a pass when a child part remains inactive. Run a fresh-session safe browser smoke and ST22 delta on A4H only. A failed/unavailable gate is never a pass. After evidence is complete, restore every directly deployed object on a shared target to the intended `master` state and verify activation/object state, unless the maintainer explicitly reserves that candidate for the next task.
8. Perform a final implementation review, update finding evidence, commit with a Conventional Commit subject, push the branch, open a pull request, and wait for required CI to become green.
9. After the first green PR run, audit the plan, implementation, test evidence, CI output, and development process. Apply useful process/documentation improvements to the same PR, move its plan to `docs/plans/finished/`, push, and wait for CI again. Record the final green run in the PR description or a PR comment; do not create a new evidence-only commit that invalidates the checked head.
10. Merge only after the maintainer accepts any recorded live-system limitations. Use GitHub's squash merge so the reviewed PR lands as one Conventional Commit; do not expose red/green/audit workflow commits on `master`. Pull the resulting `master`, verify Release Please behavior, and do not manually tag an ordinary release.

For a source-only candidate, a controlled direct source deployment is preferable to switching the shared native-abapGit repository away from `master`. Record the candidate commit/hash and activate only the intended object. Structural changes still require a real native-abapGit round trip and may need a dedicated package/system to avoid changing shared objects underneath other work.

When several PRs change the same ABAP object, keep them independently reviewable but integrate them sequentially. After each merge, rebase the next PR onto current `master`, resolve the source and test corpus deliberately, recompute aggregate findings/test counts, and rerun all affected local and live gates. Do not resolve a large overlap by accepting either side wholesale, and keep branch-specific counts in the finding plan/register rather than in long-lived workflow prose.

For a coordinated structural-object round trip, refresh native abapGit before staging, review all system/Git drift, and select only the intended object. Never use **Add All** when unrelated changes are present. Review the staged filenames before commit, record every intentionally unselected drift item, push, refresh again, and require the intended object to be clean.

If ARC-1's pre-write linter selects the wrong ABAP release, bypass only that local lint step after the repository's pinned abaplint gate is green. Keep server preflight, explicit activation, SAP syntax, Unit, ATC, and object-state verification enabled, and record the tooling mismatch in the findings register.

ZTOAD's report source is large enough that streaming a complete `SAPWrite` JSON payload through stdin can return `EAGAIN`. If that occurs, create a bounded temporary JSON payload file, pass its path to ARC-1, and verify the subsequent write before activation; never interpret the failed streamed request as a deployed candidate. Capture very large ATC JSON to a temporary file and emit an exact count/priority/prerequisite summary so terminal truncation cannot corrupt the evidence.

If ARC-1 authentication or a live system is unavailable, local checks may continue, but do not claim live validation. Record the missing gate in the PR and complete it before merge unless the maintainer explicitly accepts the risk.

NPL currently lacks ZTOAD's transparent table. SAP_BASIS 750 has no ADT transparent-table create endpoint, so ARC-1 cannot provision it safely. Never substitute a DDIC structure. Until the real table is provisioned outside the ADT-only workflow, record NPL ZTOAD activation/syntax/Unit/ATC as blocked even though the ARC-1 object lifecycle itself is proven usable.

## Testing rules

- New or changed non-GUI logic requires ABAP Unit coverage whenever technically feasible.
- Follow red–green–refactor: reproduce and make a focused test fail before changing production behavior.
- Existing open defects belong in the findings register; do not keep permanently failing or disabled regression tests on `master`.
- Put report test classes at the end of the program and declare them `FOR TESTING RISK LEVEL HARMLESS DURATION SHORT`.
- Prefer data-in/data-out parser and generator units with no database commits, user-specific state, frontend GUI, or persistent fixtures.
- Extract testable logic behind small local classes instead of adding more behavior to large `FORM` routines.
- Use dependency injection for external collaborators. Use test seams only as a temporary legacy-code bridge.
- Test both the success path and invalid/untrusted input. ZTOAD executes dynamic SQL, so authorization boundaries, dynamic table/column input, escaping, DML, and native SQL are security-sensitive.
- For generated source, test the actual emitted line representation: split only at whitespace outside literals, reject unsafe hard cuts, and never move `*` into ABAP source column one.
- ABAP Unit tests must not change customizing or persistent business data. Any integration test that writes must use an explicitly disposable Z table and be cleaned up.
- Local abaplint is a fast compatibility/static gate, not a substitute for SAP syntax, activation, ABAP Unit, or ATC.
- ABAP Unit and syntax cannot prove that a Control Framework class is supported by a particular frontend. GUI-control changes require a new browser session against the exact active candidate plus a post-run dump check.

## Live-system safety

- Default smoke tests to read-only `SELECT` statements against non-sensitive test data.
- Never use production data, credentials, personal data, or confidential query text in issues, commits, CI logs, or test fixtures.
- Do not enable or broaden INSERT, UPDATE, DELETE, native SQL, or authorization defaults as part of an unrelated change.
- Do not run destructive SQL merely to prove parsing. DML/native tests require an isolated table, explicit authorization, and a cleanup plan.
- Resolve and record the ATC variant used on each system. Prefer the same effective checks on both systems.
- Record whether an ATC run was complete. Zero displayed findings with missing prerequisite checks is incomplete, not a pass.
- Before judging a UI product regression, verify the installed dynpro, GUI status, transaction, and other serialized prerequisites. Record installation drift as its own finding while keeping the overall end-to-end gate blocked.

## Files and release automation

- Keep abapGit object files under `src/`; root documentation and CI files are outside `.abapgit.xml`'s `/src/` starting folder.
- Keep active plans under `docs/plans/`, completed plans under `docs/plans/finished/`, and dated research under `docs/research/`.
- Preserve lower-case abapGit filenames and LF line endings.
- Do not reformat the legacy report as part of an unrelated fix.
- Release Please owns `CHANGELOG.md`, `version.txt`, and the annotated version lines in `README.md` and `src/ztoad.prog.abap` after bootstrap.
- Do not manually tag ordinary releases. Merge the Release Please PR after its checks and version diff are reviewed. With the default `GITHUB_TOKEN`, approve its queued Quality workflow in GitHub before waiting for green CI.
