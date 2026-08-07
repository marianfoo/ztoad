# BASE-BUG-001 NPL compatibility closure plan

_Created: 2026-08-07 · finding: `BASE-BUG-001` · target branch: `codex/fix-base-bug-001-npl`_

## Objective

Close the SAP_BASIS 750 gate that remained pending after the strict aggregate clause-order fix. The production clause-order implementation is already green on A4H. NPL now has the complete native-abapGit installation and proves that the regression fixture itself uses aggregate syntax unavailable on SAP_BASIS 750.

## Root cause and red evidence

- Exact `origin/master` source is active on NPL with no inactive main-source divergence.
- Active SAP syntax passes with zero errors.
- ABAP Unit is red at 66/67: `LTC_QUERY_GENERATOR->GENERATES_STRICT_AGGREGATE` cannot create its subroutine pool.
- Isolated NPL compiler probes reject `COUNT( FIELDNAME )` before clause placement is considered. Moving `INTO` does not change that error.
- NPL accepts `COUNT( * )` and `COUNT( DISTINCT FIELDNAME )`; the complete sanitized strict aggregate compiles when both `COUNT` expressions use `DISTINCT`.

The test is intended to guard the placement of `INTO TABLE` after `HAVING` and `ORDER BY`. It is not intended to require a newer non-distinct `COUNT( sql_exp )` grammar. The fixture can therefore use `COUNT( DISTINCT FIELDNAME )` without weakening the protected invariant.

## Scope

1. Replace the two fixture occurrences of `COUNT( FIELDNAME )` with `COUNT( DISTINCT FIELDNAME )` in `generates_strict_aggregate`.
2. Preserve the `SELECT DISTINCT`, `MAX`, `GROUP BY`, `HAVING`, `ORDER BY`, and strict host-variable result path.
3. Update the finding register, NPL dossier, and system matrix with exact evidence.
4. Make no production-code, authorization, parser, generator, dynpro, table, transaction, or serializer change.

The table enhancement-category warning discovered during installation is a separate structural finding and is excluded from this source-only PR.

## Implementation and review

- Keep the existing behavior-focused test name and assertions.
- Review the modified query as ABAP 7.50 syntax and as a faithful regression for the original clause-order defect.
- Run the repository-pinned abaplint gate and manually review the touched test for focused Arrange–Act–Assert structure, readability, and `HARMLESS`/`SHORT` test-class policy.
- Confirm the diff contains no generated metadata or unrelated legacy formatting.
- Clean Core is unaffected: the change is a test fixture and introduces no API dependency.

## Local gates

1. `npm ci`
2. `npm test`
3. `npm run lint:quality` and compare the diagnostic inventory without promoting it to a required gate
4. `git diff --check`
5. Complete diff and security review
6. Freeze the candidate in a commit and record the commit plus local source SHA-256

## Live gates

### NPL / SAP_BASIS 750 first

1. Deploy the exact frozen report source through ARC-1/ADT.
2. Activate `PROG ZTOAD` explicitly.
3. Require equal active/inactive main source and no inactive ZTOAD composite part.
4. Require active SAP syntax with zero errors.
5. Require all 67 ABAP Unit tests to pass.
6. Run complete ATC variant `DEFAULT`; compare its finding counts with the 88-finding master baseline and reject unexplained additions.

### A4H / SAP_BASIS 758

1. Keep native abapGit on `refs/heads/master`; deploy the exact source candidate directly.
2. Activate explicitly and require equal active/inactive source plus no inactive ZTOAD child part.
3. Require SAP syntax and all 67 ABAP Unit tests to pass.
4. Re-run the recorded ATC variants and compare with their baselines.
5. Browser smoke and ST22 delta are not applicable because only an ABAP Unit query literal changes; production/runtime source and serialized UI objects remain byte-for-byte unchanged.

After evidence, restore both shared targets to the intended `master` source unless the candidate has already merged and become `master`. Verify activation, source state, syntax, and the relevant Unit baseline after restoration.

## Rollback

Revert the two `DISTINCT` additions and redeploy the previous `master` source. No DDIC conversion, persistent data migration, transport cleanup, or UI rollback is involved.

## Plan review

- The smallest correction changes only the invalid fixture grammar.
- The original red failure and compiler probes establish the reason for the change.
- The strict clause-order invariant remains exercised.
- Both supported releases receive authoritative syntax and Unit evidence.
- Structural table cleanup remains isolated for a separate native-abapGit round trip.

## Validation evidence

- Frozen candidate commit: `9e8d881`
- Local source SHA-256: `de46fab9bb8aa908c2efa66abe0c0f428f7f125b6bba81272990215964128831`
- Server-normalized candidate SHA-256 on both systems: `c7d4cbcfcb9a3af1d322e3f912c586dfee12b8af0fe608049807cfa61e94cccd`
- Local: `npm ci`, `npm test`, repository/installation contracts, and `git diff --check` green; configured abaplint 0 findings; diagnostic quality inventory unchanged at 2,169 findings across 63 rules.
- NPL 750: explicit activation; equal active/inactive source; zero inactive ZTOAD parts; syntax 0 errors; 67/67 Unit; ATC `DEFAULT` unchanged at 88 (3 P1, 4 P2, 81 P3).
- A4H 758: native abapGit remained on `refs/heads/master`; direct candidate activation; equal active/inactive source; zero inactive ZTOAD parts; syntax 0 errors plus the two pre-existing POSIX warnings; 67/67 Unit; `ABAP_CLOUD_READINESS` unchanged at 682 (474 P1, 208 P2); `S4HANA_READINESS_2023` returned zero rows but retains its documented prerequisite limitation.
- Browser/ST22: not applicable because production behavior and serialized UI objects are unchanged.
- Restore: both systems explicitly restored and activated to exact `origin/master` `d532b2e`, server SHA-256 `e32d7d3b8bebdb38457cd81f52e90a3b00dc0e830ac537b7690b70cee4544897`, with equal source and no inactive ZTOAD part. A4H restored at 67/67; NPL restored at the intentionally reproduced 66/67 pre-fix baseline.
