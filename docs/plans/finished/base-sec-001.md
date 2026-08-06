# BASE-SEC-001 plan: prevent generated ABAP injection

_Date: 2026-08-06 · branch: `codex/fix-base-sec-001`_

## Goal

Prevent parser output from escaping the intended SQL statement and becoming additional ABAP in a generated subroutine pool, without removing the supported SQL workbench surface.

## Patch contract

- Vulnerable path: editor input → procedural parser fragments → `QUERY_GENERATE` / `QUERY_GENERATE_NOSELECT` → `SYNTAX-CHECK FOR` → `GENERATE SUBROUTINE POOL` → later execution.
- Attacker prerequisite: a crafted fragment reaching either generator. The current editor usually strips a top-level period, so exact end-to-end UI reachability is reduced but not accepted as the generator's security boundary.
- Invariant: every emitted user-derived fragment remains inside one intended ABAP SQL statement before and after 255-character source wrapping; source terminators/comments/host references, unsafe line splits, and unsupported literal forms fail before generation.
- Preserved behavior: covered SELECT/DML syntax, SQL identifiers/functions/operators, single-quoted and decimal/negative literals, parser-stripped `INTO`, SAP_BASIS 750 syntax, and existing authorization decisions. ABAP type namespaces fail closed until they can be recognized in a grammar-aware CAST position.
- Out of scope: native SQL retirement (`BASE-SEC-002`), nested-source authorization (`BASE-SEC-003`), complete SQL grammar/parser redesign, and adding a new per-column authorization model.

## Reviewed sequence

1. Trace both generated-program paths and compare SAP guidance for generated code and external ABAP SQL tokens.
2. Add harmless generator regressions proving that old SELECT and UPDATE code accepts a valid statement-injection payload. Generate but never execute the pool; deploy the test-only source to A4H and record red.
3. Review the plan for include-list completeness, false positives, literal/decimal handling, 7.50 compatibility, Clean ABAP/Clean Core, and independence from SEC-002/SEC-003.
4. Add a pure local input validator at the last shared pre-generation boundary. Use a positive character include list plus explicit single-quote, decimal-period, numeric-minus, and whitespace rules.
5. Guard both generators, preserve quote/comment semantics across generated-line wrapping, clear the output program on rejection, return safely from the non-SELECT caller, and add focused validator/unit tests for valid and invalid boundaries.
6. Run `npm ci`, `npm test`, `npm run lint:quality`, `git diff --check`, exploit reversion review, and a complete diff/security review.
7. Deploy the exact candidate to A4H through ARC-1, explicitly activate, and run active syntax, all ABAP Unit tests with coverage, active/inactive comparison, inactive-child inventory, and both recorded ATC variants.
8. Start a fresh A4H transaction with no SQL execution and verify the ST22 delta; retain missing `STATUS010` as `BASE-BUG-007`.
9. Probe NPL through ARC-1/ADT only and record the existing missing-object prerequisite without GUI fallback.
10. Update the finding register, open a draft PR, require first green CI, audit the workflow and implementation, apply useful process improvements, finish this plan, and require final green CI.

## Plan review

- The failing regressions exercise the real generator boundary and prove exploitability without executing injected code or touching data.
- Validation after parsing preserves the safe removal of caller-provided `INTO` targets and avoids treating characters inside SQL literals as ABAP source.
- A positive character policy is easier to audit than an ABAP-keyword deny list. Explicit decimal/minus rules preserve common numeric predicates without allowing a general statement terminator or `sy-uname` form; an adversarial `ABAP.<word>` lookalike remains rejected rather than creating a context-free period exception.
- Guarding both generators avoids a SELECT-only fix while leaving native SQL wholly owned by SEC-002.
- The local class is cohesive and pure; replacing the generic pool architecture remains a later structural change.
- Generated-line wrapping is part of the sink contract. A safe character set is insufficient if a 255-character split can separate an escape pair or move `*` into source column one; unrepresentable long tokens now fail closed.

## Evidence log

- Baseline restore: A4H explicitly restored to master source SHA-256 `f30e88b6e0a52fd15d6fdaf09e383b22629bb069c55317a7d9a2e9c565cf8694`; activation has the four known warnings and 19/19 ABAP Unit tests pass.
- SAP Docs MCP: generic generated programs are the least safe dynamic technique; external SQL table/column/condition tokens require include-list checks and external values must be escaped or bound.
- ABAP Unit red: the test-only source activated on A4H with the four known warnings. Exactly the two exploit regressions failed because both generators returned a valid subroutine-pool name: `LTC_QUERY_GENERATOR.REJECTS_STATEMENT_INJECTION` and `LTC_COMMAND_PARSER.REJECTS_DML_INJECTION`. The other 19 tests passed. Coverage was 17.01% statements, 13.94% branches, and 7.89% procedures. Neither pool was executed and no SQL ran.
- Implementation: `LCL_QUERY_INPUT_VALIDATOR` now applies a positive character/literal-state contract immediately before both generated-program sinks. Both generators clear the returned pool name before validation, and `QUERY_PROCESS` stops before incrementing the pool counter or showing the DML confirmation when generation is rejected.
- Adversarial review: an initial exception for apparent `ABAP.<type>` CAST namespaces was removed because it inferred grammar from four preceding letters. The final rule accepts periods only inside quoted data or numeric decimals and includes a regression for `AS ABAP.WRITE ...`; typed CAST namespaces deliberately fail closed.
- Local: `npm ci`, `npm test`, and `git diff --check` pass. Configured abaplint reports zero issues. The diagnostic full profile reports 1,919 findings across 59 rules versus 1,878/58 at the branch point; the 41-finding delta is explained by the raw profile's conflicting naming rules, inline/format preferences, tests, and two reused message texts. No diagnostic suppression was added.
- A4H exact candidate: local source SHA-256 `8e48e9d138623379b4429150873efeddb5777528f3ead2523aa4f0b94243d224` was written through ARC-1 with SAP preflight and explicitly activated. Active syntax has zero errors and the four known warnings. All 34 ABAP Unit tests pass; coverage is 19.88% statements, 17.24% branches, and 11.39% procedures. ADT active/inactive state has no divergence; the server-normalized active SHA-256 is `198d37158b9f4f5f607e92792663d36e14d8a5c449bad8057298e538b8e7f6a0`.
- A4H structural/ATC: the system inventory remains 49 inactive entries, including the seven known ZTOAD report/child entries. `ABAP_CLOUD_READINESS` reports 775 findings (465 P1, 310 P2): the seven additions over master are two classic message statements and five test-only `SY-REPID`/`PERFORM` findings; the validator implementation adds no released-API finding. `S4HANA_READINESS_2023` returns no rows but remains non-authoritative because seven prerequisite checks are unavailable.
- A4H smoke: a fresh FLP `ZTOAD` transaction reached the editor with no SQL entered or executed. The known missing `STATUS010` message remains. The newest MARIAN ST22 dump is still the pre-existing `CL_GUI_SOURCEEDIT` dump at `2026-08-06T09:30:59Z`; there is no post-smoke dump.
- NPL: ARC-1 1.0.2 over ADT only reconfirmed 404 for both `PROG ZTOAD` and `TABL ZTOAD`. Exact 7.50 activation/Unit/ATC remains prerequisite-blocked; no GUI/browser fallback or unfaithful structure substitute was used.
- First CI: GitHub Actions Quality run `31108200911` passed on head `c07a09e961c40e6266e144ea7121aebefc19c1cf`; the required repository-quality job and configured abaplint check are green. The observations check is informational/neutral as designed.

## Post-green final review and process audit

- Re-read the complete production diff and traced all generator callers. Both SELECT and INSERT/UPDATE/DELETE sinks validate after parser normalization and before emitting source; rejection clears the program handle, and DML orchestration returns before incrementing `w_run`, confirmation, or execution.
- Replayed the exploit invariant against the tests: removing either sink guard restores the corresponding red generator test. The test pools are never executed and the positive DML test generates but does not run SQL.
- Reviewed preserved syntax and false-positive risk. Literals, doubled quotes, decimals, negative numbers, subtraction, namespace slashes, aliases, functions, and operators are covered. ABAP CAST type namespaces remain an explicit fail-closed limitation rather than weakening the period rule.
- Reviewed local diagnostics and ATC deltas. A follow-up declaration cleanup removed the two new legacy prefixes and two chained-declaration contributions; the diagnostic profile remains non-gating because its naming rules conflict. The two new production Cloud-readiness findings are classic `MESSAGE` statements used for safe user feedback, not unreleased APIs in the validator.
- Reviewed CI configuration and first-run output. It checked out the PR head, installed pinned dependencies, and ran the repository ABAP/contract gates successfully; no workflow change was warranted.
- Process improvement: `docs/development.md` and `docs/test-strategy.md` now require an explicit representation invariant plus a valid/adversarial pair for every allow-list exception. This directly addresses the overly broad `ABAP.<word>` exception caught during final review.
- Integration note: merge P0 PR #18 first, this PR #20 second, and PR #19 last. Rebase/revalidate after each predecessor and do not resolve the large ABAP overlap by accepting one side wholesale.
- Final CI: post-audit head `573dab6f1d687067db6ff9023096ddad2ac157fe` passed GitHub Actions Quality run `31108341355` plus the configured external abaplint check; the observations check remained informational as designed.

## Maintainer-requested follow-up process audit

- The shared primary test target had retained this unmerged source after validation. It was restored through ADT to the branch-point `master` source SHA-256 `f30e88b6e0a52fd15d6fdaf09e383b22629bb069c55317a7d9a2e9c565cf8694`; activation succeeded, syntax retained the four known warnings, 19/19 baseline tests passed, and active/inactive state matched.
- The workflow now freezes a source/object commit before expensive live evidence and explicitly invalidates that evidence after any production or serialized-object change.
- Shared direct-deployment targets now have a required restore-and-verify handoff. Concurrent report PRs now require sequential merge, deliberate rebase, aggregate evidence recomputation, and affected live revalidation.
- Final CI run links belong in the PR description/comment after success so recording evidence cannot create an infinite evidence-only CI loop.
- The sanitized retrospective is stored in `docs/research/2026-08-06-p0-development-process-retrospective.md`. The follow-up head acceptance is recorded in PR #20 rather than by another post-green evidence commit.

## External-review follow-up

- A test-only A4H replay confirmed the 255-character question was real: a balanced SQL literal with its doubled quote split across the old hard-cut boundary passed validation and still produced a subroutine pool. No generated pool was executed and no SQL ran.
- `LCL_GENERATED_LINE_SPLITTER` replaces the procedural splitter and splits only at whitespace outside literals, rejects a line with no safe split, and rejects a continuation that would place `*` in ABAP source column one. Both generator sinks stop before `GENERATE SUBROUTINE POOL` when the layout cannot be preserved.
- The DML sink now handles a failed `SYNTAX-CHECK` symmetrically with SELECT: user-visible error styling, cleared program handle, and explicit return. The red test previously ended with classic exception `E001(00)`; it now returns normally with no pool.
- Long unbroken tokens and long literals without an outside-literal split point are deliberately rejected. This is preferable to silently changing their ABAP-source representation.
- Final exact candidate: source SHA-256 `9d44d07b14fd26eae8ae6899529bd5a0a8535a36734ea177c495c1c099e97be7` and server-normalized active SHA-256 `1b2ad196292ab5f761dde3ff1d15e9b08fa77dc7cf15de3cc5d75fc808571b84`. A4H syntax has zero errors and three warnings, active/inactive source matches, and all 39 tests pass with 21.59% statement, 19.28% branch, and 14.63% procedure coverage. `ABAP_CLOUD_READINESS` reports 676 findings (467 P1, 209 P2); `S4HANA_READINESS_2023` returns no rows but remains incomplete. Local configured abaplint stays at zero, while the diagnostic inventory is 1,986 findings across 59 non-gating rules.
