# BASE-BUG-003 plan: support ABAP SQL string functions

_Date: 2026-08-07 · branch: `codex/fix-base-bug-003-v2`_

## Goal

Make the SQL functions reported in GitHub issue #4 generate valid result structures on SAP_BASIS 750 and S/4HANA 2023 without regressing legacy fields, strict aggregates, CASE handling, aliases, literal data, authorization, or generated-source safety.

## Patch contract

- Failing path: editor query → `QUERY_PARSE` → `QUERY_GENERATE` inference copy → global comma replacement and whitespace split → invalid component type → failed generated-program syntax check.
- Root cause: result-item separators, function-argument separators, and literal commas are collapsed before expression classification.
- Invariant: inference may replace only top-level commas outside quoted literals; the original validated SELECT fragment remains byte-for-byte unchanged when emitted.
- Compatibility: all new production syntax and APIs must activate on SAP_BASIS 750. Any supported 7.50 function, including one-argument `LENGTH`, must select strict clause order.
- Preserved behavior: simple fields, `table~*`, aliases, CASE, COUNT, AVG/SUM/MIN/MAX, legacy space-separated lists, comma lists, row limits, source authorization, input validation, and safe line splitting.
- Out of scope: a complete SQL grammar, inline result-table redesign, newer-release function families, and general aggregate-of-arbitrary-expression support.

## Reviewed implementation sequence

1. Confirm the official 7.50 function family, grammar, result types, and strict clause order through the SAP Docs MCP.
2. Add generator regressions for `SUBSTRING`, nested `CONCAT`/`SUBSTRING`, a comma and blank inside a literal, and one-argument `LENGTH`.
3. Replay those tests against current production code on NPL and require all inherited tests to remain green.
4. Add a pure local select-list inference scanner. Test top-level versus nested commas, doubled quotes, literal lookalikes, the complete 7.50 family, and unbalanced input.
5. Use the scanner in `QUERY_PARSE` for strict-function detection and in `QUERY_GENERATE` for the inference copy only.
6. Add one focused generator branch for top-level supported function results: `LENGTH` uses `TYPE i`; character-like functions use `TYPE string`; an explicit alias remains the ALV reference label.
7. Run `npm ci`, `npm test`, the diagnostic full abaplint profile, `git diff --check`, a complete diff review, and focused authorization/representation review.
8. Freeze the exact candidate commit and source hash before live validation.
9. On NPL first, then A4H, require explicit activation, active/inactive main equality, no inactive ZTOAD child parts, active syntax, all ABAP Unit tests, and complete ATC or an explicit prerequisite failure.
10. On A4H, run a read-only exact-candidate browser smoke for `SUBSTRING` and nested `CONCAT`, and compare ST22 before and after. Do not use browser or GUI automation on NPL.
11. Restore both shared targets to exact `master`, repeat activation and state checks, then perform the final implementation and process review.
12. Push a Conventional Commit branch, open the PR, wait for green CI, apply process improvements to the same PR, move this plan to `docs/plans/finished/`, wait for green CI again, squash merge, and refresh local `master`. Do not merge Release Please PR #23.

## Plan review

- A pure scanner is the smallest coherent OO extraction. It gives deterministic data-in/data-out tests and does not require test seams or persistent data.
- Recognition must occur outside literals; text such as `'CONCAT('` cannot enable strict generation.
- Expression completeness must track nested parentheses and doubled single quotes. An incomplete inference representation fails closed before source generation.
- The generator must retain its existing CASE analyzer rather than replace it with the older prototype's source version.
- `TYPE string` intentionally represents a safe receiving type, not exact type inference. `LENGTH` is separately typed as integer according to SAP's contract.
- The initial implementation will be reviewed against the current CASE, source-authorization, input-validator, and line-splitter changes before live deployment.
- The stale NPL MCP allowlist is handled only by the bounded direct runner configured with `SAP_ALLOWED_PACKAGES=*`; all normal preflight, activation, syntax, Unit, ATC, and state gates remain enabled.

## Evidence log

- SAP Docs MCP: the eight functions and strict checks are part of the ABAP 7.50 contract; arguments are nested SQL expressions separated by commas.
- Local red candidate: commit `f75fad1cc5c4db61a959053591473cb60a68c781`, source SHA-256 `5b7f042d1dd4fb185b48d0584a05a36e0985be2d9349888baf9bb6b27e5cd974`; repository `npm test` is green because dynamic generated programs execute only in SAP.
- NPL red: explicit activation succeeded; active/inactive source equality passed at server SHA-256 `2a940658489e68b867072a54215e14a683506b4c7c3f2d5c7c4d34923eefee0c`; 67 inherited Unit tests passed and the four intended function regressions failed.
- Final local candidate: commit `6a2971bded5ff273b82b1db4c4b15b84485612b6`, local source SHA-256 `4f07726e262d06a42fa56257197bd22ce5d1654fbf64919e9069f2a28deb3256`. `npm ci`, `npm test`, configured abaplint, repository/install contracts, and `git diff --check` are green. The full diagnostic profile is 2,230 findings versus 2,168 on exact master; the +62 consists only of the default profile's conflicting clean-name/Hungarian-name rules. No avoidable parser, syntax, security, return-code, formatting, or obsolete-code finding was added.
- Final NPL/SAP_BASIS 750 candidate: explicit activation, zero syntax messages, 78/78 Unit tests, equal active/inactive source at server SHA-256 `36ebfcba68733ff91655ec552298af8ec5d19a203767aa88f34dedc67d7e6f83`, no inactive ZTOAD part, and unchanged complete `DEFAULT` ATC at 88 findings (3 P1, 4 P2, 81 P3).
- Final A4H/SAP_BASIS 758 candidate: explicit activation, zero syntax errors plus the two existing POSIX warnings, 78/78 Unit tests, the same equal active/inactive server source hash, and no inactive ZTOAD part. Complete `ABAP_CLOUD_READINESS` is unchanged from master at 682 findings (474 P1, 208 P2). `S4HANA_READINESS_2023` returned zero rows but remains prerequisite-incomplete rather than a pass.
- Final A4H runtime: separate fresh sessions executed `SUBSTRING( DD03L~FIELDNAME, 1, 3 ) AS PREFIX` and nested `CONCAT( DD03L~TABNAME, SUBSTRING( ... ) ) AS LABEL`, each returning five read-only DD03L rows with the expected ALV alias. Client-side comparison found no new ST22 dump after the pre-smoke 65-entry marker; the newest entry remains 2026-08-07 06:26:10 UTC.
- Browser-driver diagnostic: programmatic `fill` without a real TextEdit change/blur left the SAP backend with an empty statement. Fresh-session real typing plus blur exercised the supported stream-read contract and passed. This was test-driver behavior, not a product failure and not accepted as runtime evidence.
- Shared-target restoration: exact master `e5ae759aa0ea8d6a2f5efb7a53fd0956ec5b3286` (local source SHA-256 `de46fab9bb8aa908c2efa66abe0c0f428f7f125b6bba81272990215964128831`) was redeployed and explicitly activated on both systems. Each reports equal active/inactive server SHA-256 `c7d4cbcfcb9a3af1d322e3f912c586dfee12b8af0fe608049807cfa61e94cccd`, 67/67 master Unit tests, clean syntax for its release, and no inactive ZTOAD part.

## Post-green process audit

- PR #27's first head run passed the repository Quality job and both external abaplint checks. The Quality job already exercises the pinned ABAP 7.50 lint plus repository and installation contracts, so this change identified no justified CI expansion.
- The final security diff review found no reportable regression, but its generic extension classifier initially omitted `src/ztoad.prog.abap`. Permanent guidance now requires reconciling every review worklist with `git diff --name-only` and explicitly adding omitted ABAP source.
- The live browser smoke showed that assigning the query through a DOM-level fill can leave the SAP TextEdit backend unchanged. Permanent guidance now requires real user-like editor input plus its change/blur sequence and acceptance based on the exact executed result, not the browser field value alone.
- No production or serialized-object content changed after the frozen candidate, so the recorded syntax, Unit, ATC, inactive-object, browser, ST22, and restoration evidence remains valid.

## Rollback

Revert the candidate source commit and deploy the exact `master` report source through ARC-1, activate explicitly, verify active/inactive equality and inactive child parts, then rerun syntax and all ABAP Unit tests. No DDIC data, customizing, screen, authorization, or serialized structural object is changed by this patch.
