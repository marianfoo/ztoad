# ZTOAD development and live-test playbook

This is the normative workflow for future issues and features. Its goal is fast local development without losing the SAP repository metadata or the evidence that a change works on both supported runtimes. The detailed red–green–refactor contract is in [test-strategy.md](test-strategy.md), and the ordered work list is [baseline-findings.md](baseline-findings.md).

## 1. Architecture and trust boundaries

ZTOAD is not only `src/ztoad.prog.abap`. The report also depends on its program metadata and dynpros (`ztoad.prog.xml`), persisted-query table (`ztoad.tabl.xml`), authorization object (`ztoad_auth.suso.xml`), and report transaction (`ztoad.tran.xml`).

Use each tool for the part it can represent faithfully:

| Tool/location | Role | Source of truth? |
|---|---|---|
| Git repository | Versioned source, reviews, CI, releases | Yes, for released versions |
| Native abapGit | Complete SAP-object serialization/deserialization and branch pull/push | Yes, for system ↔ Git round trips |
| abaplint | Fast local parsing, 7.50 syntax floor, and XML consistency | No; local preflight only |
| ARC-1 | System discovery, dependency reads, object state, syntax, ABAP Unit, ATC, and controlled targeted writes | Authoritative for the connected live system |
| ARC-1 source mirror | Searchable read-only snapshot | No; it does not contain all abapGit metadata |
| ABAP 7.50 NPL | ADT-only minimum-release activation, syntax, Unit, and ATC gate after one-time offline native-abapGit provisioning | Yes |
| S/4HANA 2023 system | Current-platform compile/runtime gate | Yes, for 2023 behavior |

The local repository and SAP systems must not diverge silently. Every system-side correction is exported through native abapGit and reviewed as a Git diff.

## 2. Local environment

Prerequisites:

- Git
- Node.js 18 or newer (CI currently uses Node.js 24)
- npm
- Access to native abapGit in each test system
- Optional but recommended: ARC-1 connections for both test systems, one server instance per SAP destination

Bootstrap and run the local gate:

```sh
npm ci
npm test
```

`@abaplint/cli` is pinned exactly because the project does not claim semantic-version compatibility. The config uses abaplint's canonical release `v762`, which maps to on-premise SAP_BASIS 750. The initial rule set deliberately concentrates on parsing, syntax, type resolution, includes, method consistency, line endings, and abapGit XML consistency. It creates a zero-warning baseline for this legacy report. Add stricter rules only with the refactoring that resolves their existing findings.

`npm test` also checks the complete native-abapGit installation closure: the source/object files, four dynpros with their separately serialized flow-logic files, and three GUI statuses. Native abapGit 1.133.0 stores each dynpro's flow logic in `ztoad.prog.screen_<number>.abap`; the program XML still carries the screen layout and CUA metadata. For a live composite-object gate, capture `SAPRead(type="INACTIVE_OBJECTS")` as JSON and run `node scripts/installation-contract.mjs --inactive-objects <file>`. Unrelated inactive objects are ignored; any ZTOAD source, CUA, screen, or text part makes the gate fail.

## 3. Native abapGit setup on the complete-object test system

Use native abapGit on A4H for complete object round trips. The repository already declares `/src/` as its starting folder and `PREFIX` folder logic, so the root package name may differ per system. NPL validation remains ARC-1/ADT-only: do not use its FLP, WebGUI, SAP GUI, or browser automation. Its complete object set was provisioned once by the maintainer with native abapGit's offline ZIP workflow because SAP_BASIS 750 has no ADT transparent-table create endpoint.

For an isolated sandbox with no transport requirement, use a local package such as `$ZTOAD`. For a shared/transportable test package, use a customer package selected by the system owner and record its transport layer. A4H now uses transportable package `ZTOAD`, layer `ZDEV`, and request `A4HK906379`. Do not create a second clone in the same system: ABAP object names are system-global, so two ZTOAD work states cannot coexist under different packages.

Setup procedure:

1. Open transaction `ZABAPGIT`.
2. Create an online repository for `https://github.com/marianfoo/ztoad`.
3. Select `master` for the initial installation and bind it to the chosen empty package. Keep this shared repository on `master` during normal source-only PR testing.
4. Pull and activate all objects.
5. Query inactive objects and require the ZTOAD installation-closure command above to pass. Main-source equality is insufficient for a composite program.
6. Confirm that the repository status is clean.
7. Run ZTOAD once with the read-only smoke query below.

If the ARC-1 abapGit bridge is used to restore the shared branch after a coordinated round trip, pass `refs/heads/master`, not only `master`, and verify the selected branch with a fresh `list_repos` call. On the current A4H bridge the short value returned success without changing the repository, while the full ref switched it correctly. Re-run the inactive-child contract after restoration.

On A4H, the Fiori-shell URL for the transaction is:

`https://a4h.marianzeis.de/sap/bc/ui2/flp?sap-client=001#Shell-startGUI?sap-ui2-tcode=ZABAPGIT`

Do not manually install only the report source. That omits the dynpros, table, authorization object, and transaction and cannot reproduce a supported installation. The repository-managed launcher is report transaction `ZTOAD` for program `ZTOAD`; use `#Shell-startGUI?sap-ui2-tcode=ZTOAD` or standalone `~transaction=ZTOAD` for its A4H smoke test.

For an offline NPL refresh, create an offline repository bound to the dedicated local package, import a ZIP generated from the exact Git commit, review and pull only `PROG ZTOAD`, `TABL ZTOAD`, `TRAN ZTOAD`, and `SUSO ZTOAD_AUTH`, then activate. Do not export the system-local root package as `package.devc.xml`, and do not accept release-normalized table metadata without a deliberate structural review. After this one-time structural provisioning, deploy source-only candidates directly through ARC-1 and keep all NPL validation UI-free.

Current ARC-1 TABL `dryRun` requests can still create an inactive draft. After any DDIC dry-run or preflight, compare active/inactive object state immediately; never infer non-mutation from the option name or success text. The A4H abapGit ADT backend also uses version-specific staging/pull XML namespaces, so an empty ARC-1 stage result is not proof of a clean repository—verify the raw bridge result or native client before pushing.

## 4. Local-first TDD flow with a stable `master`

`master` remains the only long-lived integration/release line and the normal branch of each shared native-abapGit link. Development uses a short-lived pull-request branch so CI and review can evaluate the candidate without placing an unreviewed state on `master`.

1. Synchronize local `master`, create `codex/<finding-id>`, select one finding, and confirm the target systems have no unrelated differences.
2. Research and reproduce the problem on the oldest available affected system. Check fixture and serialized UI-metadata availability before making a spike permanent.
3. Add the smallest test, replay the original production code, and record the intended red failure.
4. Write and review a plan under `docs/plans/` covering implementation, ABAP 7.50, Clean ABAP/Clean Core, local/live tests, rollback, browser smoke, and ST22. A security plan must separately state actor prerequisites, proven entry-point reachability, demonstrated sink behavior, and the invariant enforced by the patch so a sink-level proof is not presented as an end-to-end exploit without evidence.
5. Edit source locally and make the smallest production change that turns the test green. For a frontend or other environment-dependent assumption, keep the candidate classified as a spike until live integration evidence accepts it. Keep serializer XML unchanged for a source-only fix. At any external-text-to-code boundary, state the representation invariant explicitly. Treat every allow-list exception as grammar: prove its context, add an adversarial lookalike regression, and fail closed when the parser cannot distinguish data from source syntax.
6. Run `npm ci`, `npm test`, `git diff --check`, and the final local/security review. For generated or otherwise transformed input, compare pre- and post-transformation semantics, especially comments, quoting, escaping, length limits, and inserted line/token boundaries. Commit and freeze the exact source/object candidate before the expensive live gates, and record its commit plus source hash. Any later `src/` or serialized-object change invalidates the affected live evidence and must be redeployed and rechecked.
7. Deploy the exact candidate source to SAP_BASIS 750 first through ARC-1/ADT when its real dependencies exist; record any missing ADT prerequisite as blocked. Keep the A4H native-abapGit link on `master` and record an unmerged candidate as a direct deployment. Follow every write with an explicit activation call, active/inactive main-object comparison, and an inactive-child-part query for affected composite objects; a write response, activation option, or equal main-source hash alone does not prove that screens, statuses, texts, and includes are active.
8. On NPL, activate only the intended object and run active syntax, all ABAP Unit tests, and complete ATC variants through ARC-1. On A4H/SAP_BASIS 758, repeat those checks and additionally start a fresh browser session for safe smoke and ST22 delta. Verify required dynpros/GUI statuses before attributing an end-to-end failure to the source candidate.
9. If a correction must be made in SAP, export it through native abapGit or reproduce it locally, then review every serialized/source difference. Never leave an unexported system-only fix.
10. Perform a final review, update evidence, commit/push the short-lived branch, open the PR, and wait for CI. After the first green run, audit the process/CI, update guidance in the same PR, move the plan to `docs/plans/finished/`, push, and wait again. Put the final run link in the PR description/comment after it passes; committing that run ID would create a new unchecked head and an avoidable CI loop. After maintainer acceptance, use GitHub's squash merge so the PR lands as one Conventional Commit even though its branch preserves red/green/audit history.

Always test 7.50 first. A change that uses newer syntax may appear correct on 2023 yet be impossible to activate on the compatibility floor. The complete NPL installation and `arc-1-750` lifecycle are now proven; source candidates must pass activation, syntax, all Unit tests, ATC, and inactive-object checks there before A4H validation. See [the NPL dossier](research/2026-08-06-npl-adt-only-validation.md).

Native abapGit branch switching changes real system objects, and abapGit Flow remains beta. Do not use either casually in the shared package. Structural-object PRs may require a dedicated package/system or an explicitly coordinated temporary branch procedure.

A direct candidate deployment changes shared mutable state even when the native-abapGit link remains on `master`. After collecting the evidence, redeploy and explicitly activate the intended `master` object, then verify syntax, the relevant Unit baseline, and active/inactive state. The only exception is an explicit maintainer reservation for immediate follow-up work, recorded with the deployed commit/hash.

For concurrent PRs that touch the same report, merge one at a time. Rebase the next branch onto the new `master`, combine the production logic and complete test corpus deliberately, recompute aggregate finding/test counts, and rerun affected local/live gates. Long-lived playbooks describe the policy; exact branch counts belong in the finding register and finished plan so parallel PRs do not overwrite one another with incompatible snapshots.

If ARC-1's pre-write linter reports an incorrect ABAP release, do not weaken all write checks. After the pinned repository abaplint gate passes, disable only the mis-profiled local lint request, retain server preflight, activate explicitly, and run SAP syntax/Unit/ATC/object-state checks. Track the tool mismatch separately from the product change.

For the large ZTOAD report, an ARC-1 stdin write can fail with `EAGAIN` before SAP receives the source. Retry through a bounded temporary JSON payload file, then require a successful write response and explicit activation. Large ATC result JSON can exceed terminal output limits; capture the complete result first and derive exact finding counts, priority counts, and prerequisite errors from that complete payload rather than parsing truncated console text.

## 5. Structural object changes

Examples include adding issue #2's transaction code, changing the table definition, changing dynpros or text elements, and adding a global class.

For these changes:

1. Create/change the object on the ABAP 7.50 development system when the object type exists there.
2. Activate and run the relevant checks.
3. Refresh native abapGit and review the complete diff before staging. If unrelated system/Git drift is present, record it and never use **Add All**.
4. Select only the affected object, review the staged filenames, and push it to the pull-request branch after its relevant checks are green.
5. Refresh again and require the intended object to be clean; unrelated unselected drift may remain only when it is explicitly documented.
6. Pull locally, inspect every generated file, and run `npm test`.
7. Deploy the same pull-request candidate into 2023 and validate deserialization, explicit activation, main-object state, and all affected inactive child parts.

If an object can only be created correctly on 2023, export it there first, then prove that the serialized form can be pulled and activated on 7.50 before accepting it. Do not fix serializer XML by guesswork.

## 6. ABAP Unit policy

The current program is a large procedural report with GUI and database dependencies. The sustainable route is incremental extraction, not a one-time rewrite:

- Move parsing/tokenization and generated-query construction behind small local classes.
- Keep pure methods data-in/data-out.
- Inject database, authorization, frontend, and repository access behind narrow interfaces when a changed path needs them.
- Put report-local tests at the end of the report so they remain with the code under test.
- Use `setup` for a fresh fixture per test; avoid shared mutable fixtures.
- Prefer clear Arrange–Act–Assert tests with one behavior per test method.
- Use test seams only for legacy statements that cannot yet be dependency-inverted, then remove the seam during later refactoring.

Required declaration pattern:

```abap
CLASS ltc_query_parser DEFINITION
  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.
  PRIVATE SECTION.
    METHODS parses_case_in_aggregate FOR TESTING.
ENDCLASS.
```

The live-passing baseline grows with each finding across `LTC_QUERY_PARSER`, `LTC_QUERY_INPUT_VALIDATOR`, `LTC_QUERY_GENERATOR`, `LTC_LINE_SPLITTER`, `LTC_COMMAND_PARSER`, and `LTCL_EDITOR_CONFIGURATION`; the current exact count belongs in the findings register and finished plan rather than this long-lived playbook. The next regression corpus should cover the existing open parser reports:

- aggregate functions around `CASE` (issue #7)
- SQL string functions such as `SUBSTRING` and `CONCAT` (issue #4)
- placement of `INTO TABLE` after `HAVING`/`ORDER BY` in strict SQL mode (issue #6)
- comments, quoted dots, aliases, joins, unions, old syntax, and 7.50 new syntax

Ordinary reports cannot use a separate native test include. Keep report-local tests with the legacy code until a cohesive area is extracted to a global class; abapGit can then serialize the class test include separately. See [the packaging research](research/2026-08-06-abap-unit-test-packaging.md).

ABAP Unit tests should be `HARMLESS` and `SHORT`. Tests that alter persistent data are integration tests and need a disposable Z table, a dedicated user/role, and explicit cleanup.

## 7. Live quality gate

Run these checks for the complete ZTOAD object set on both systems:

1. Native abapGit status and deserialization check are clean.
2. All imported objects activate.
3. SAP syntax check passes for program `ZTOAD`.
4. ABAP Unit passes with no skipped relevant tests.
5. ATC completes with the recorded project variants and has no new unapproved finding. A `S4HANA_READINESS_2023` run with unavailable prerequisite checks is incomplete even when it returns no finding rows. Treat `ABAP_CLOUD_READINESS` as an architectural information/burn-down signal, not a zero gate; record exact dated totals in the [baseline findings register](baseline-findings.md), not this long-lived playbook.
6. Manual read-only browser smoke tests pass on A4H; NPL UI smoke is not applicable by maintainer direction.
7. Authorization-negative tests confirm that unauthorized tables/activities remain blocked.
8. ST22 and, when relevant, Gateway/system logs contain no new errors from the test.

When ARC-1 is connected, use the equivalent read-only/diagnostic calls:

```text
SAPRead(type="SYSTEM")
SAPRead(type="COMPONENTS")
SAPManage(action="probe")
SAPLint(action="list_rules")
SAPDiagnose(action="syntax", name="ZTOAD", type="PROG")
SAPDiagnose(action="unittest", name="ZTOAD", type="PROG")
SAPDiagnose(action="atc_variants")
SAPDiagnose(action="atc", name="ZTOAD", type="PROG", variant="<recorded variant>")
```

ARC-1 is intentionally one destination per server instance. Configure distinct server entries, for example `arc-1-750` and `arc-1-2023`, instead of changing credentials in place and losing which system produced a result.

Minimal read-only smoke query:

```abap
SELECT SINGLE mandt FROM t000
```

Then exercise the parser feature being changed with a sanitized query and verify both the generated source and result. Never use INSERT, UPDATE, DELETE, or native SQL against SAP/business tables for smoke testing. Such tests are permitted only against an isolated disposable Z table with explicit authorization.

`BASE-RUN-001` established the plain TextEdit fallback. `BASE-BUG-007` restored the complete active program installation and GUI status. `BASE-RUN-006` then proved that WebGUI needs an explicit capability adapter rather than the desktop Control Framework workspace: its supported core is an empty stream-read editor with deterministic last-statement selection plus ALV result, while repository/DDIC trees, initial text population, frontend selection/cursor execution, history refresh, splitter sizing, and other desktop frontend services remain excluded until tested individually. Keep product behavior failures separate from incomplete system metadata, and never run this browser protocol on NPL.

Use `npm run lint:quality` to reproduce the non-blocking full default-rule inventory. Record exact dated totals and intentional deltas in the [baseline findings register](baseline-findings.md); do not copy volatile counts into this long-lived playbook. The raw defaults contain conflicting prefix/no-prefix naming rules, so the strict profile must resolve that configuration conflict explicitly while the raw inventory remains visible. Continue the [active zero-findings plan](plans/abaplint-zero-findings.md); only promote the resolved strict command to required CI after it is green.

## 8. Security review for every parser/execution change

ZTOAD accepts dynamic ABAP SQL from a user, generates executable code, and can support DML/native SQL. A functional parser fix can therefore change an authorization boundary.

For every relevant change, verify:

- table and activity authorization checks still occur for every accessed/modified table;
- external table and column names cannot bypass intended restrictions;
- values are bound or safely quoted instead of concatenated where possible;
- comments, aliases, nested expressions, subqueries, and unions cannot hide additional statements;
- wrapping, splitting, generated-source layout, or other representation changes do not alter comment/quote boundaries or resume hidden input as executable code; generated lines split only at a grammar-safe boundary, and a hard length cut, split inside a literal, or continuation that moves `*` into ABAP source column one must fail closed;
- row limits remain enforced unless the user explicitly requests the documented override;
- Native SQL remains unconditionally rejected and forbidden sinks such as `C_DB_EXECUTE` do not return;
- error/generated-code displays do not leak credentials or confidential values.

Run ATC security checks on the live systems. Local abaplint cannot prove runtime authorization or dynamic-SQL safety.

## 9. Release flow

Release Please runs on pushes to `master` and reads Conventional Commit messages. The repository starts from version `4.0.4`; its manifest avoids replaying old history. It maintains:

- `CHANGELOG.md`
- `version.txt`
- the annotated version in `README.md`
- the annotated version comment in `src/ztoad.prog.abap`

When a `fix:` or `feat:` change reaches `master`, Release Please opens or updates one release PR. Review its version and changelog, let Quality pass, and merge it to create the unprefixed SemVer tag and GitHub Release. The action intentionally uses the repository `GITHUB_TOKEN` by default. GitHub places the resulting pull-request Quality workflow in an approval-required state; a maintainer must approve that run and wait for green CI. See [setup-evaluation.md](setup-evaluation.md) before switching to a GitHub App or fine-grained PAT for unattended triggering.

## 10. Primary references

- [SAP ABAP Unit test class documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPCLASS_FOR_TESTING.html)
- [SAP ATC development guideline](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENABAP-TESTCOCKPIT_GUIDL.html)
- [SAP dynamic ABAP SQL injection guidance](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_INJ_DYN_TOKENS_SCRTY.html)
- [SAP ABAP 7.50 SQL strict mode](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENABAP_SQL_STRICTMODE_750.html)
- [SAP Clean ABAP](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md)
- [abapGit repository settings](https://docs.abapgit.org/user-guide/repo-settings/dot-abapgit.html)
- [abapGit folders and files](https://docs.abapgit.org/user-guide/reference/folders-filenames.html)
- [abapGit stage and commit](https://docs.abapgit.org/user-guide/projects/online/stage-commit.html)
- [abapGit Flow (beta)](https://docs.abapgit.org/user-guide/reference/flow.html)
- [abaplint local setup](https://github.com/abaplint/abaplint/blob/main/docs/getting_started.md)
- [Release Please Action](https://github.com/googleapis/release-please-action)
- [Release Please manifest configuration](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md)
- [GitHub `GITHUB_TOKEN` workflow-trigger behavior](https://docs.github.com/en/actions/concepts/security/github_token#when-github_token-triggers-workflow-runs)
