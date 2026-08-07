# BASE-BUG-004 plan: parse top-level ABAP SQL clauses

_Date: 2026-08-07 · branch: `codex/fix-base-bug-004`_

## Goal

Make `QUERY_PARSE` identify only top-level `SELECT`, `FROM`, tail, `UNION SELECT`, caller-target, and row-limit clauses while preserving literal data, nested parenthesized content, multiline input, authorization coverage, and the exact executable SQL representation.

## Patch contract

- Failing path: editor query → raw substring/regex searches in `QUERY_PARSE` → a literal/nested/comment/multiline lookalike is treated as structural SQL → wrong slicing or mutation before authorization and generation.
- Root cause: clause detection operates on unclassified user text and uses single-space delimiters.
- Invariant: structural offsets come only from a same-length, quote- and parenthesis-aware top-level view; every slice/removal is applied by that exact offset to the untouched original representation.
- Failure policy: unbalanced quote/parenthesis state or a surviving double-quote comment fails closed before branch splitting, authorization, or generation.
- Compatibility: use only syntax and APIs available on SAP_BASIS 750; the scanner is a pure local class with no database or frontend dependency.
- Preserved behavior: current source authorization, input validator, select-list inference, strict-function handling, safe generated-line splitting, explicit/default row-limit behavior, legacy `UNION SELECT`, and caller-provided INTO removal.
- Out of scope: complete SQL grammar, `UNION ALL` and branch-layout repair (`BASE-BUG-005`), unlimited-row policy (`BASE-RUN-004`), and previously rejected source forms.

## Reviewed implementation sequence

1. Keep red commit `8ec4040` as the reproducible baseline: 78 inherited tests green and exactly six new parser tests red on NPL.
2. Add `lcl_sql_clause_scanner`, returning a same-length view with literal/nested content masked and an explicit invalid flag.
3. Add pure scanner tests for doubled quotes, nested parentheses, multiline whitespace, unbalanced states, comments, and exact length/offset preservation.
4. In `QUERY_PARSE`, scan before any mutation. Find only top-level `UNION SELECT`, split by mapped offsets, then rescan the first branch.
5. Detect and remove only a top-level `UP TO n ROWS`; preserve a literal/nested lookalike. Rescan after removal.
6. Detect caller `INTO`/`APPENDING` only at top level, anchor the existing target grammar at that proven offset, remove its exact range, then rescan.
7. Derive `SELECT`, `FROM`, and the first top-level `WHERE`/`GROUP BY`/`HAVING`/`ORDER BY` boundary with whitespace-tolerant patterns on the masked view. Slice the original query only.
8. Keep the existing authorization scanner on the final executable branch representation and require every inherited authorization/security/generator test to remain green.
9. Run `npm ci`, `npm test`, diagnostic abaplint delta, `git diff --check`, complete diff/Clean ABAP/security review, and freeze the exact candidate commit plus source hash.
10. Validate on NPL first and A4H second: explicit activation, active syntax, all Unit tests, active/inactive main equality, no inactive ZTOAD child part, and complete ATC or explicit prerequisite failure.
11. On A4H, use a fresh WebGUI session with real editor typing/blur for a sanitized multiline query containing literal `FROM`/`UP TO` lookalikes and an actual five-row limit; verify expected ALV rows/alias and compare ST22 after the pre-smoke marker.
12. Restore both shared systems to exact `master`, push a Conventional Commit branch, open the PR, wait for first green CI, audit the process/CI, move this plan to `docs/plans/finished/`, wait for green again, and squash merge only after accepted evidence. Leave Release Please PR #23 unmerged.

## Plan review

- A same-length view is preferred to normalized token text because offsets remain auditable across the representation boundary.
- The scanner must not return an executable query. Its output is structure-only and masked data must never reach `GENERATE SUBROUTINE POOL`.
- Early comment rejection closes the ordering gap where the old UNION split removed comment text before `lcl_sql_source_scanner` could reject it.
- All searches must run against the current masked view. Reusing offsets after a removal is forbidden.
- The INTO regex remains narrowly responsible for target grammar, but it is anchored at a scanner-proven top-level keyword so literal/nested text cannot trigger it.
- The change should remove duplicated raw searches from `QUERY_PARSE` without reformatting unrelated legacy code.
- Security review must reconcile `git diff --name-only` explicitly so `src/ztoad.prog.abap` cannot be omitted by a generic extension classifier.

## Test matrix

- Valid: simple/strict SELECT, doubled-quote literal containing `FROM`, literal `UNION SELECT`, literal `UP TO n ROWS`, JOIN literal containing `ORDER BY`, multiline SELECT/FROM/WHERE, nested parentheses, explicit limit, caller target, legacy UNION.
- Invalid: unbalanced single quote, unmatched opening/closing parenthesis, surviving comment before a UNION lookalike, missing top-level FROM.
- Preserved security: unauthorized nested source, UNION source, comments, dynamic/path/hierarchy/CTE sources, statement injection, wrapped literals, and every generated-line boundary test.
- Live: 84+ Unit tests on both releases, syntax/activation/state, ATC delta, fresh A4H read-only WebGUI result, and ST22 delta.

## Exact-candidate evidence

- Frozen source commit: `1b76755c1af07325ff50f76ffa12661bc45213d1`; local source SHA-256: `8897954b5235e9c88c7e4bcd9653eccdd9f4b5235958792fe2c7e5b40cfbec1f`.
- Red proof: NPL activated the original production code with 78 inherited tests green and exactly six focused parser regressions red. The implementation and expanded corpus then produced 91/91 green tests on both supported releases.
- Local gates: `npm ci`, `npm test`, and `git diff --check` passed. Configured abaplint remains at zero. The diagnostic profile is 2,355 findings across 62 rules versus master at 2,230; no increase occurred in `dangerous_statement`, `ambiguous_statement`, `sql_escape_host_variables`, or `strict_sql`.
- NPL/SAP_BASIS 750: explicit activation, zero syntax errors, 91/91 Unit, equal active/inactive source at server SHA-256 `fa0332e5679236d636bece64cbb3e28b3dccf2e8b21112c69efadd550ea78d0b`, no inactive ZTOAD part, and complete unchanged DEFAULT ATC of 88 findings (3 P1, 4 P2, 81 P3).
- A4H/SAP_BASIS 758: explicit activation, zero syntax errors, 91/91 Unit, equal active/inactive source at the same server hash, and no inactive ZTOAD part. Seven POSIX-regex deprecation warnings document the compatibility tradeoff for using the 7.50-supported regex API. ABAP_CLOUD_READINESS stayed unchanged at 682 findings (474 P1, 208 P2); S4HANA_READINESS_2023 returned zero rows but remains prerequisite-incomplete.
- A4H WebGUI: a fresh session received `SELECT CONCAT( 'FROM', TABNAME ) AS LABEL` / `FROM DD02L` / `UP TO 5 ROWS` via real typing and blur. The grid returned five `FROM...` values and the backend reported five entries. The full post-smoke dump set contained no ID newer than the `2026-08-07T06:26:10Z` marker.
- Shared-system restoration: NPL and A4H were restored to exact master `0f056e8`; both report server SHA-256 `36ebfcba68733ff91655ec552298af8ec5d19a203767aa88f34dedc67d7e6f83`, zero active syntax errors, 78/78 Unit, active/inactive equality, and no inactive ZTOAD part.

## Implementation and security review

- The same-length structural view is never executed. All SELECT/FROM/tail/UNION slices come from the original query by scanner-proven offsets.
- The unchanged full-query source scanner remains after clause extraction, so nested and UNION sources still pass through the existing authorization policy. Every inherited authorization and generator regression remains green.
- Invalid quote/parenthesis state, surviving comments, backticks, and templates fail before branch splitting or generation. Re-scanning after each removal prevents stale offsets crossing a representation boundary.
- The seven new A4H syntax warnings are not hidden as green findings: they are an explicit 7.50-versus-758 API compatibility limitation and do not change either target's complete ATC baseline.

## Rollback

Revert the scanner integration commit, deploy exact `master` report source through ARC-1, activate explicitly, verify active/inactive equality and inactive child parts, then rerun syntax and all ABAP Unit tests. No table data, DDIC metadata, customizing, transaction, screen, or authorization object is changed.
