# BASE-BUG-004 research: top-level ABAP SQL clause boundaries

_Research date: 2026-08-07 · minimum target: SAP_BASIS 750 SP02 · branch: `codex/fix-base-bug-004`_

## Finding

`QUERY_PARSE` does not identify grammar. It runs independent raw-string searches for `UNION SELECT`, `UP TO n ROWS`, `SELECT`, `FROM`, `WHERE`, `GROUP BY`, `HAVING`, and `ORDER BY`. Those searches cannot distinguish a top-level clause from identical text inside a quoted literal, nested parentheses, a surviving comment, or a line-break-separated clause.

This produces distinct incorrect behaviors:

- a `FROM` lookalike inside the select list truncates the inferred select list;
- a `UNION SELECT` lookalike inside a literal creates another branch;
- `UP TO n ROWS` inside literal data is deleted and changes the main query's row limit;
- a tail-clause lookalike inside a join condition moves the FROM/tail boundary;
- line breaks around `FROM` or `WHERE` make otherwise valid editor input unparseable;
- a surviving comment can be split before the existing source scanner gets the opportunity to reject it.

The source authorization scanner is already quote-aware, but it runs after these destructive splits. It therefore cannot repair or reliably reject a query whose structural representation was already changed.

## SAP grammar contract

The official Standard ABAP SQL reference describes `SELECT` as a main query followed by optional set operators, target, and row restriction. `UP TO` has different placement rules in main queries and subqueries and applies to the preceding query result. The `UNION` reference models set operators between complete query branches. These are lexical/query-level boundaries, not arbitrary substrings.

Sources consulted through the SAP Docs MCP:

- [SELECT](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPSELECT.html)
- [UNION, INTERSECT, EXCEPT](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPUNION.html)
- [Query clauses for set operators](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPUNION_CLAUSE.html)
- [UP TO and OFFSET](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPSELECT_UP_TO_OFFSET.html)

The patch does not attempt to implement the complete latest SQL grammar. It needs only a release-neutral lexical view that preserves string length and exposes keywords at parenthesis depth zero. The original validated query remains the executable representation.

## Red evidence

- Test-only commit: `8ec4040a27114c7ea1a0a7e7a9468847ec78d910`
- Local source SHA-256: `3fb6d1a515de31323e7490805583180ace34e8cd42ac264753b838a3da6734a3`
- Local `npm test` and `git diff --check`: green; local tooling does not execute ABAP Unit or generated programs.
- NPL write used ARC-1 1.0.2 with `SAP_ALLOWED_PACKAGES=*`, server preflight enabled, local pre-write lint disabled only because the persistent profile still has the already documented stale release/allowlist state, and a separate explicit activation.
- NPL active syntax: zero errors.
- NPL active/inactive main source: equal at server-normalized SHA-256 `dd984512b30a4d3b2de3fb84a17e99daa321dbca15221d527638c0f528ff89a3`.
- ABAP Unit: 84 tests total; all 78 inherited tests passed and exactly the six new tests failed: literal `FROM`, literal `UNION`, literal `UP TO`, literal tail keyword, multiline clauses, and comment/UNION ordering.
- The global inactive inventory contains unrelated development objects but no ZTOAD main or child part.

## Recommended boundary

Add one pure local scanner that produces a same-length top-level view:

- preserve characters only at parenthesis depth zero and outside quoted literals;
- replace literal and nested content with spaces so every reported offset still maps to the original query;
- support doubled single quotes and all ABAP whitespace;
- reject unbalanced quotes/parentheses and a surviving double-quote comment before any split;
- derive all structural offsets from the top-level view, then slice/remove only the corresponding range in the original query;
- rescan after removing a top-level row-limit or caller target because offsets change.

This is smaller and safer than a full SQL parser, reusable by the legacy FORM boundary, deterministic under ABAP Unit, and compatible with the SAP_BASIS 750 floor.

## Deliberate limits

- `UNION ALL`, branch layout compatibility, and per-branch semantics remain `BASE-BUG-005`.
- Unlimited result policy remains `BASE-RUN-004`.
- Dynamic/CTE/path/hierarchy/parenthesized-join source policy remains unchanged and fail-closed.
- The patch does not normalize or rewrite literal data, nested query text, or the emitted SQL fragment.
