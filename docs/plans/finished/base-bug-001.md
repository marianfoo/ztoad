# BASE-BUG-001 implementation plan and evidence

## Scope

Fix [GitHub issue #6](https://github.com/marianfoo/ztoad/issues/6): a comma-separated `SELECT DISTINCT` with aggregates, `GROUP BY`, and `HAVING` is rejected while ZTOAD syntax-checks its generated subroutine pool with “The INTO/APPENDING clause must be at the end of the SELECT.”

This is a source-only correction to report `ZTOAD`. It does not change serialized object metadata, authorization policy, database data, or the query result layout.

## Research and red-test evidence

- Local `master` and active A4H `ZTOAD` matched exactly after CRLF normalization before the spike.
- A4H had no inactive draft, the active report had no syntax error, and all 14 baseline ABAP Unit tests passed.
- `QUERY_PARSE` correctly keeps the `WHERE`/`GROUP BY`/`HAVING` tail and sets `fw_newsyntax = abap_true` when the select list contains commas.
- `QUERY_GENERATE` originally emitted the target and row limit before `FROM`:

  ```abap
  SELECT DISTINCT ...
  INTO TABLE @t_result
  UP TO ... ROWS
  FROM ...
  ...
  ```

- ABAP 7.50 strict mode requires the main-query `INTO` clause after `FROM` and all data-source clauses. Only additions such as `UP TO`, `OFFSET`, and database hints may follow it. See the official [ABAP SQL strict-mode documentation](https://help.sap.com/doc/abapdocu_750_index_htm/7.50/en-US/abenabap_sql_strictmode_750.htm) and [`SELECT` syntax](https://help.sap.com/doc/abapdocu_750_index_htm/7.50/en-US/abapselect.htm).
- The first draft used the issue's `VBAK` names, but A4H does not install `VBAK`; that failure was discarded because it did not prove the clause-order defect. An installed `SFLIGHT` spike then isolated the exact error. The permanent fixture uses `DD03L`, an existing ZTOAD dependency present on both supported ABAP releases, to avoid depending on optional application or demo content.
- An independent A4H syntax spike proved that the corrected issue-shaped statement compiles, while ZTOAD's original ordering fails with the exact issue message. The permanent fixture includes `GROUP BY`, `HAVING`, `ORDER BY`, and the generated default row limit so all clauses around `INTO` are covered.
- The issue-shaped `LTC_QUERY_GENERATOR=>GENERATES_STRICT_AGGREGATE` test was activated against the original production generator. Of 17 tests, 16 passed; only the strict aggregate test failed because `QUERY_GENERATE` returned no generated program. This is the authoritative red replay.

## Planned production change

1. Keep the current pre-`FROM` target and limit placement for legacy queries where `fw_newsyntax` is initial. Moving legacy `INTO` to the final position would itself activate strict mode and could reject the deliberately unescaped legacy host target.
2. For strict/new-syntax multi-row queries, emit clauses in this order:

   ```abap
   SELECT [DISTINCT] ...
   FROM ...
   [WHERE ... GROUP BY ... HAVING ... ORDER BY ...]
   INTO TABLE @t_result
   [UP TO ... ROWS].
   ```

3. Keep the existing scalar `COUNT( * )` generation unchanged. A live spike and compatibility test show that its earlier `INTO` placement already compiles because it does not contain the comma-separated select list that activates this strict-mode rule.
4. Keep the parser, field-list/type construction, authorization checks, row-limit semantics, subroutine execution, and legacy-query path unchanged.
5. Refactor only the touched multi-row clause-emission block if doing so improves clarity without widening the behavior change.

## Test plan

### Focused ABAP Unit coverage

- Keep the red issue-shaped `DISTINCT`/`COUNT`/`MAX`/`GROUP BY`/`HAVING` generator test.
- Add an escaped scalar `COUNT( * )` compatibility test to protect the separate, unchanged generation branch.
- Add a legacy select generator test to prove the compatibility path still compiles.
- Run all existing parser, line-splitting, and command-parser tests.

The generator tests only ask SAP to syntax-check and generate a temporary subroutine pool. They do not execute the user query or read business rows.

### Local gates

- `npm ci`
- `npm test` with the pinned abaplint version and repository ABAP 7.50 compatibility configuration
- `git diff --check`
- Confirm that a source-only fix leaves native-abapGit serializer XML unchanged

### A4H / SAP S/4HANA 2023 gates

1. SAP pre-write syntax check of the complete candidate source.
2. Controlled source update on transport `A4HK906379`.
3. Inactive syntax check, activation, and active syntax check with no new warnings.
4. All ABAP Unit tests green.
5. Run ATC `S4HANA_READINESS_2023` and `ABAP_CLOUD_READINESS`; distinguish a complete zero result from a run that cannot execute prerequisite checks.
6. Confirm no inactive divergence and no new relevant ST22 dump from non-browser verification.
7. Attempt the read-only FLP/WebGUI smoke and record it as failed if the already-known transaction/startup blockers remain. Do not misreport that gate as skipped or passed.

### ABAP 7.50 gate

The official syntax rule and repository lint configuration cover the 7.50 language floor, but the separate live SAP_BASIS 750 destination is still not configured in this workspace (`BASE-ENV-001`). This remains a missing live acceptance gate, not a pass.

## Quality, security, and clean-core constraints

- Use ABAP 7.50-compatible syntax and keep the change readable within the existing legacy `FORM` boundary.
- Do not combine this bug fix with broad formatting, parser replacement, or unrelated Clean ABAP cleanup.
- Do not add a test-only production hook or weaken authorization checks.
- Do not execute or persist data in unit tests.
- The fix introduces no new SAP API dependency and therefore does not worsen the production code's current clean-core classification. Existing dynamic code generation and the broader parser/security findings remain separately tracked.
- Preserve the issue input as a sanitized string fixture; do not log credentials or result data.

## Rollback

Before each live write, verify there is no unrelated inactive draft. If activation or verification fails for a reason unrelated to the intended red test, restore the last active source from Git `master`, activate it, and rerun the baseline syntax and Unit suite.

## Plan review

Approved before production implementation, with the following conclusions:

- **ABAP 7.50 compatibility:** final-position `INTO` is the required strict-mode form and is available on the compatibility floor. Applying it only when `fw_newsyntax = abap_true` avoids forcing legacy queries into strict mode.
- **Behavioral scope:** the red test proves that only the comma-separated multi-row path needs correction. Escaped scalar `COUNT( * )` and legacy selects have explicit green compatibility tests so the fix does not widen into their working paths.
- **Testability:** the production boundary already returns an empty program when its generated code fails SAP syntax checking. Testing that public `FORM` outcome exercises the real parser, type builder, clause generator, and SAP compiler without adding a test-only seam. Extracting the large generator during this bug fix would add disproportionate regression risk; a focused extraction remains future refactoring work.
- **Readability:** keep the clause-order decision adjacent to clause emission, add comments that explain the strict-versus-legacy reason, and avoid a macro or abstraction that hides SQL order.
- **Clean ABAP/Clean Core:** this is an appropriate clean island in touched legacy code. No new production dependency or unreleased API is introduced, and broad procedural cleanup is deliberately excluded.
- **Security:** the regression tests generate but never execute the query. The fix neither expands accepted input nor bypasses existing authorization logic; the broader dynamic-SQL findings remain open.
- **Verification limitations:** A4H can prove the exact runtime compiler behavior. Live 7.50 and browser functional acceptance remain explicitly constrained by `BASE-ENV-001`, `BASE-RUN-001`, and `BASE-BUG-006`.
- **Tooling observation:** ARC-1's duplicate pre-write lint currently interprets this report as ABAP 7.02 and rejects an existing `VALUE` expression, while the pinned repository lint and SAP syntax checks pass. Use the latter two gates for this change and address the ARC-1 configuration mismatch in the post-PR process audit.

## Implementation and verification evidence

- Implemented the reviewed two-path clause order: legacy multi-row queries retain their pre-`FROM` target/limit, while strict multi-row queries emit `INTO TABLE @t_result` after the data-source tail and `UP TO` after `INTO`.
- Added three harmless, short generator tests. The complete suite is now four classes and 17 methods.
- Local `npm ci`, pinned abaplint 2.120.18 (`npm test`), and `git diff --check` are green; configured abaplint reports 0 issues across four serialized files.
- A4H saved and activated only `REPS ZTOAD`; the editor reported `aktiv`. No serializer XML changed.
- A4H syntax check: 0 errors and the same four baseline warnings (three POSIX-regex deprecations and the existing unsupported kernel call).
- A4H ABAP Unit: 17 methods processed, all green.
- A4H `S4HANA_READINESS_2023`: no finding rows were shown, but the run was incomplete because seven prerequisite checks are not configured. It is not recorded as a clean zero gate.
- A4H `ABAP_CLOUD_READINESS`: 767 findings (466 P1, 301 P2). Two P2 `FORM` warnings are directly in the new test helper at its two `PERFORM` calls; they are necessary to characterize the current procedural boundary and disappear when the generator is extracted to a class. The production fix adds no finding. The other seven-warning difference from the recorded 758 baseline does not occur in the changed class and is retained as a baseline/tool-result discrepancy for the process audit.
- FLP direct launch was blocked by the automation browser's popup policy. Standalone launch confirms there is still no `TRAN ZTOAD` (`BASE-BUG-006`). Executing the report created a new 07:56:39 UTC `RAISE_EXCEPTION` dump in `SAPLCNDP`, matching the known `CL_GUI_ABAPEDIT` startup blocker (`BASE-RUN-001`). Browser acceptance therefore remains failed.
- Live SAP_BASIS 750 validation remains unavailable (`BASE-ENV-001`) and must not be inferred from local lint.

The plan is complete when the local gate and pull-request CI are green, the implementation has passed final diff review, and all unavailable or failed live gates are stated in the pull request.

## Post-PR process audit

Pull request [#15](https://github.com/marianfoo/ztoad/pull/15) passed its first Quality run: the required ABAP 7.50 abaplint job and hosted abaplint check were green. The audit found these process gaps:

- repository guidance still described direct development on `master` even though review and CI are safer on a short-lived branch;
- the shared SAP abapGit repository and the Git candidate branch were not distinguished clearly enough for source-only live testing;
- `docs/development.md` still named Node.js 22 while CI uses Node.js 24;
- the live gate did not explicitly distinguish an incomplete ATC run from a true zero-finding result;
- plan/research/completed-plan locations, fixture-availability checks, final review, and the post-first-green audit were not normative;
- the full hosted abaplint debt could not be reproduced concisely with a local command;
- test packaging and possible ABAP 7.02/downport distributions lacked written decisions.

The same PR therefore updates `AGENTS.md`, the development/test playbooks, PR template, and setup evaluation; adds the non-blocking `npm run lint:quality` inventory; records the 7.02 and ABAP Unit packaging research; and creates the active zero-findings plan. Required CI remains the focused zero-finding `npm test` gate because the full inventory is still 1,857 findings. No CI workflow was weakened or broadened during this bug fix.
