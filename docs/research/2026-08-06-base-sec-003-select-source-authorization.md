# BASE-SEC-003 SELECT source authorization research

_Date: 2026-08-06 · finding: `BASE-SEC-003`_

## Revalidated authorization bypass

`QUERY_PARSE` currently derives `FW_FROM`, prepends `JOIN`, splits that string at spaces, and authorizes only the token immediately following each top-level `JOIN`. The rest of the parsed statement is copied into `FW_WHERE` and later into a generated subroutine pool.

For a query such as `SELECT carrid FROM scarr WHERE carrid IN ( SELECT carrid FROM sflight )`, only `SCARR` is checked. `SFLIGHT` sits in the tail and reaches generated ABAP SQL without a table authorization check. The same flat-token model is fragile around nested subqueries, parenthesized sources, comments, literals containing SQL keywords, and later SQL constructs.

The default authorization object normally makes this path reachable to a user whose allowed outer table differs from an unauthorized inner table. The fallback pattern configuration has the same bypass when it is narrower than `*`.

## Security contract

- Every physical data source introduced by `FROM` or `JOIN` in each generated SELECT branch must pass the existing table/activity authorization policy before generation.
- Nested subqueries must not hide an additional source.
- `FROM` or `JOIN` text inside string literals or string templates must not create false authorization checks. A comment that reaches the scanner must fail closed because generated-source line wrapping can change where it ends; the normal editor path strips ordinary line comments before this boundary.
- Dynamic data-source syntax and unsupported CTE syntax must fail closed because the physical source cannot be proven by this parser.
- Attached and detached path-expression sources and the exact `HIERARCHY(` source constructor must fail closed because authorizing their leading syntax token does not prove the physical repository source used by the full `FROM` grammar. A normal table whose name merely starts with `HIERARCHY_` remains valid.
- Existing simple sources, aliases, joins, subqueries, and per-branch UNION processing must remain usable when every source is authorized.

## Options evaluated

### Keep checking only the parsed top-level FROM clause

Rejected. It cannot see sources in `WHERE`/`HAVING` subqueries, so it does not satisfy the existing authorization promise.

### Reject every query containing a subquery

Rejected. It would close the bypass but remove a documented and useful query form even when all physical sources are authorized.

### Build a complete ABAP SQL grammar

Deferred. A complete cross-release grammar belongs with the broader parser redesign and strict-token work. Implementing it inside one P0 fix would be difficult to review and would overlap `BASE-SEC-001` and the P1 parser findings.

### Add a quote-aware physical-source scanner with fail-closed comments

Selected. A small pure local class scans the current SELECT branch character by character, ignores quoted content, and collects each token following `FROM` or `JOIN` at any nesting depth. The existing authorization check is then applied once per unique source. Parenthesized dynamic names, parenthesized join expressions, host-variable sources, comments that survive editor normalization, path expressions, hierarchy constructors, and `WITH`/CTE input fail closed. The scanner sees the complete input branch, so a later `UNION ALL` source is checked even though the legacy parser does not split that spelling into a separate branch.

Comments that reach this boundary are rejected rather than ignored. `EDITOR_GET_QUERY` normally strips `"` comments line by line first, so the direct scanner test is a boundary test rather than proof that every ordinary editor comment reaches it. If a comment survives normalization, `QUERY_GENERATE` feeds the fragment through `ADD_LINE_TO_TABLE`, which wraps generated ABAP source at 255 characters. The scanner cannot safely treat the remaining text as permanently commented out.

ABAP SQL path expressions require special care here. SAP documents the data-source form as an exposed unit followed directly by a backslash association, while also permitting a source line break in front of the backslash. Rejecting only tokens whose first character is `\` therefore covered the detached lookalike but missed `zi_view\_association`. The final scanner rejects a backslash anywhere in a source token. Parenthesized joins, valid on newer targets, remain a deliberate fail-closed limitation until their complete source grammar is modeled.

This is intentionally an authorization scanner, not a claim that all other external SQL tokens are safe; strict validation of table, field, and tail syntax remains `BASE-SEC-001`.

## Test design

- Red: a restricted fallback policy allows `SCARR` but must reject `SFLIGHT` in a nested subquery; the old parser incorrectly accepts it.
- Green: authorize nested sources when both match, reject a second nesting level, preserve an ordinary authorized join and a real `HIERARCHY_*` table, and ignore `FROM`/`JOIN` inside a literal.
- Fail closed: reject source comments that reach the scanner, a parenthesized dynamic data source or join expression even under wildcard authorization, both attached and detached path-expression sources, the exact hierarchy constructor, and unsupported `WITH` input before generation.
- Set-operation boundary: prove that `UNION ALL`, despite the legacy parser's incomplete branch split, cannot hide an unauthorized later source from the scanner.
- Regression: retain all existing parser/generator/editor/DML tests and run the full live suite.

No query is executed for security proof. The test exercises the parser boundary directly and the A4H browser smoke starts the transaction only.

## Compatibility and clean-core impact

The scanner uses classic string offsets, internal tables, and local classes available at the SAP_BASIS 750 floor. It adds no unreleased dependency and separates a pure authorization concern from the procedural parser. It does not make the generated-program architecture clean-core compliant; it prevents one authorization bypass within that legacy boundary.

## SAP sources

- [SQL Injections in Dynamic Tokens](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_INJ_DYN_TOKENS_SCRTY.html) requires external dynamic table sources to be checked against an include list and treats dynamic WITH tokens as injection-sensitive.
- [SQL Injections in Generated Programs](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_INJ_GEN_PROG_SCRTY.html) classifies generic generated programs as the least safe dynamic-programming technique.
- [Subqueries in WHERE Conditions](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENWHERE_LOGEXP_SUBQUERY.html) confirms that subqueries can be nested and have their own FROM sources.
- [ABAP SQL Strict Modes](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENABAP_SQL_STRICT_MODES.html) confirms that the 7.50 SQL parser includes all earlier strict-mode rules.
- [ABAP SQL FROM Clause](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPFROM_CLAUSE.html) documents both dynamic-source security requirements and the line-based semantics of comment characters in dynamic tokens.
- [ABAP SQL Path Expressions](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENABAP_SQL_PATH.html) states that a data-source path follows its exposed unit directly and documents a permitted line break before a backslash.
