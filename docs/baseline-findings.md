# ZTOAD baseline findings

_Snapshot: 2026-08-06 · branch `master` · local HEAD `cae4dea2062b` plus the uncommitted test/setup baseline · live system A4H client 001, SAP_BASIS 758 SP02_

This is the ordered work list for incremental TDD. It records observed defects separately from broad style debt so a new failure cannot disappear inside the legacy backlog. A finding is closed only after its regression test is green locally where possible, green on A4H, and green on the SAP_BASIS 750 target.

## Baseline evidence

| Gate | Result | Interpretation |
|---|---|---|
| Repository `npm test` | Passed, 0 configured abaplint findings | Fast compatibility/XML gate is green |
| Full ARC-1 lint profile | 1,086 findings: 992 errors, 94 warnings, 35 rules | Existing debt; grouped below, not an immediate all-or-nothing gate |
| A4H SAP syntax | 0 errors, 4 warnings | Program compiles on SAP_BASIS 758 |
| A4H ABAP Unit | 14 passed, 0 failed | Initial parser/command/line-splitting characterization baseline is green |
| A4H ATC `S4HANA_READINESS_2023` | 0 findings | No findings from this migration-readiness variant |
| A4H ATC `ABAP_CLOUD_READINESS` | 758 findings: 466 priority 1, 292 priority 2 | Current classic report is not ABAP Cloud compatible |
| A4H WebGUI smoke | Failed | New ST22 dump `RAISE_EXCEPTION` in `SAPLCNDP`, described by `BASE-RUN-001` |
| ABAP 7.50 live gate | Not run | Separate ARC-1/abapGit destination is still required |

The four normal syntax warnings are POSIX-regex deprecation at lines 1668, 1691, and 1817, plus the unsupported `C_DB_EXECUTE` call at line 3818.

## Ordered findings register

Priority meanings: **P0** blocks the requested test workflow or is an immediate security hazard; **P1** should be handled before normal feature expansion; **P2** is planned reliability/design debt; **P3** is mechanical cleanup that should be paid down only in touched code.

| ID | Pri. | Finding and evidence | Test to drive the fix | Status |
|---|---:|---|---|---|
| BASE-RUN-001 | P0 | ZTOAD dumps immediately in WebGUI/FLP. ST22 at 2026-08-06 05:52:14 UTC shows `DATA_SOURCE_ERROR` raised by `DP_PUBLISH_URL`, called from `CL_GUI_ABAPEDIT=>CONSTRUCTOR`, `EDITOR_INIT` line 1166. | Live WebGUI test: launch ZTOAD, assert the editor screen renders and ST22 has no new dump. Add an editor-factory unit seam before selecting a browser-safe fallback. | Open |
| BASE-SEC-001 | P0 | User text becomes dynamic Open SQL and generated ABAP (`GENERATE SUBROUTINE POOL`, lines 2310 and 3657). Parser-derived table/field/tail tokens are not validated through a strict include list. | Malicious/ambiguous table, column, `WHERE`, `HAVING`, subquery, comment, and quoted-keyword cases; verify rejection before generation. | Open |
| BASE-SEC-002 | P0 | Native SQL uses unsupported kernel call `C_DB_EXECUTE` at line 3818. It is a high-impact arbitrary database-command path and produces a live compiler warning. | Authorization-negative test, default-disabled test, allow-list test against a disposable Z object, and no-kernel-call architecture test. | Open |
| BASE-SEC-003 | P0 | SELECT authorization extraction tokenizes top-level `FROM`/`JOIN` text and can miss nested subqueries/CTEs or concealed data sources. | Multi-table joins, nested subqueries, aliases, comments, quoted identifiers, UNION branches, and unauthorized inner-table cases. | Open |
| BASE-BUG-001 | P1 | [Issue #6](https://github.com/marianfoo/ztoad/issues/6): a reported `SELECT DISTINCT ... COUNT ... MAX ... GROUP BY ... HAVING` query produces “The INTO/APPENDING clause must be at the end of the SELECT.” | Sanitized `VBAK`/`VGBEL` reproduction; check exact generated ordering around `HAVING`, `ORDER BY`, `UP TO`, and `INTO TABLE`. | Open |
| BASE-BUG-002 | P1 | [Issue #7](https://github.com/marianfoo/ztoad/issues/7): a reported `SUM( CASE ... END ) AS ...` over `EKBE` produces “No component exists with the name CASE.” The expression is split into false result components. | Sanitized aggregate with multi-line `CASE`, qualified fields, multiplication, alias, WHERE, and GROUP BY; assert one aggregate expression and the expected generated row type. | Open |
| BASE-BUG-003 | P1 | [Issue #4](https://github.com/marianfoo/ztoad/issues/4): `SUBSTRING`/`CONCAT` produce “No component exists with the name SUBSTRING(”, exposing naïve select-list tokenization. | Nested function arguments, commas inside functions, aliases, literals containing spaces/commas, and function composition. | Open |
| BASE-BUG-004 | P1 | Keyword detection uses string searches and space splitting rather than quote/parenthesis-aware lexical tokens. Keywords in literals, comments, functions, or subqueries can move clause boundaries. | Quoted `FROM`, `WHERE`, `UNION`, `UP TO`; escaped quotes; comments; nested parentheses; multiline queries. | Open |
| BASE-BUG-005 | P1 | `UNION` splitting is whitespace-sensitive and does not model `UNION ALL`; branches are appended while assuming compatible result layouts. | `UNION`, `UNION ALL`, mismatched branch types/columns, per-branch limits, and keywords in literals/subqueries. | Open |
| BASE-BUG-006 | P1 | [Issue #2](https://github.com/marianfoo/ztoad/issues/2): no serialized `TRAN ZTOAD` exists, so FLP/WebGUI cannot launch a stable ZTOAD transaction directly. | Native-abapGit round-trip on both systems plus direct FLP and standalone WebGUI launch tests. | Open |
| BASE-BUG-007 | P1 | [Issue #5](https://github.com/marianfoo/ztoad/issues/5): source-only manual installation is incomplete; ZTOAD also needs dynpros/GUI status, TABL `ZTOAD`, and SUSO `ZTOAD_AUTH`. | Fresh-package native-abapGit install test verifying all objects activate and the first start reaches the editor. | Open |
| BASE-RUN-002 | P1 | Generated-program failures are not isolated into a stable error contract; dumps or generated source can leak query details. | Syntax/runtime exception tests with sanitized error output and no ST22 dump for expected bad input. | Open |
| BASE-RUN-003 | P1 | The generated subroutine-pool approach has a finite per-session pool budget and encourages session restart behavior instead of bounded execution objects. | Repeated-query stress test across the documented maximum, checking graceful handling and cleanup. | Open |
| BASE-RUN-004 | P1 | `UP TO 0 ROWS` means unlimited results. A user can accidentally run an unbounded query or expensive aggregation in an interactive tool. | Row-limit policy tests, explicit unlimited confirmation/policy test, timeout/load test on disposable data. | Open |
| BASE-RUN-005 | P1 | INSERT parsing is quote- and whitespace-sensitive and relies on dynamic component assignment/conversion. Truncation, missing fields, and conversion failures need a defined result. | Values/SET variants, embedded quotes, numeric/date conversion, too-long values, missing/duplicate fields; isolated Z table only. | Open |
| BASE-ARCH-001 | P2 | The report is over 5,000 lines with 37 lint findings for procedural-size reduction. GUI, parser, authorization, generator, and execution responsibilities are coupled. | Preserve characterization tests; extract one pure parser/generator class per fixed issue without a big-bang rewrite. | Open |
| BASE-ARCH-002 | P2 | GUI-bound globals and `FORM` routines prevent headless tests for startup, editor selection, authorization, and execution orchestration. | Introduce narrow editor/auth/executor interfaces; test factories and orchestration with doubles. | Open |
| BASE-CLEAN-001 | P2 | Clean-core status is provisionally Level D/unknown because of `CL_GUI_ABAPEDIT`, DDIC internals such as `DD03L`, system/kernel calls, and other unreleased references. Classic controls such as `CL_GUI_ALV_GRID` are Level B on-premise APIs. | Replace/encapsulate unsupported and unknown references, then re-run released-API ATC and document accepted Level B dependencies. | Open |
| BASE-TOOL-001 | P2 | ARC-1 0.9.19 can list/check this native-abapGit repository but its clone call sends an XML shape rejected by A4H 758 (`repository` namespace mismatch). Native abapGit UI was required to link/pull. | Minimal ARC-1 integration reproduction against A4H 758; fix ARC-1 separately, keep UI fallback documented. | Open |
| BASE-ENV-001 | P2 | The SAP_BASIS 750 target is not configured in this workspace, so the minimum-release promise is not yet proven for the new tests or future fixes. | Separate `arc-1-750` profile; pull `master`, activate, run syntax, Unit, ATC, and safe smoke suite. | Open |
| BASE-REL-001 | P2 | Source declares 4.0.4 but the latest Git tag is 4.0.3. Release Please correctly starts at 4.0.4 but its first compare link expects that tag. | After both live gates pass at an exact commit, decide whether to create the one-time immutable 4.0.4 tag/release. | Decision |
| BASE-CTS-001 | P3 | Setup left empty local request `A4HK906377`; active work is in `A4HK906379`. | Manual owner decision whether to retain or delete the empty request. No automated deletion. | Decision |

## Full lint debt by rule

This diagnostic profile is intentionally not the merge gate yet. New code must not add to the counts, and touched code should reduce relevant counts without mass-formatting unrelated lines.

| Rule | Count | Treatment |
|---|---:|---|
| `space_before_colon` | 505 | Mechanical; clean only in touched statements |
| `prefer_pragmas` | 122 | Replace pseudo-comments when modifying the statement |
| `preferred_compare_operator` | 109 | Mechanical Clean ABAP cleanup |
| `functional_writing` | 81 | Incremental expression cleanup |
| `check_subrc` | 50 | Review individually; reliability-relevant |
| `reduce_procedural_code` | 37 | Architectural extraction, not suppression |
| `fully_type_itabs` | 31 | Add explicit table keys/types while extracting seams |
| `prefer_is_not` | 27 | Mechanical cleanup |
| `check_syntax` | 13 | Current audit lacks the live TABL dependency and reports `ZTOAD` table resolution; verify against live SAP |
| `in_statement_indentation` | 13 | Mechanical cleanup |
| `check_comments` | 10 | Improve comments in touched areas |
| `double_space` | 10 | Mechanical cleanup |
| `sy_modification` | 8 | Refactor; direct system-field modification is fragile |
| `avoid_use` | 7 | Replace obsolete/weak constructs in touched paths |
| `obsolete_statement` | 7 | Includes `REFRESH`; migrate incrementally |
| `fully_type_constants` | 6 | Incremental typing |
| `line_break_multiple_parameters` | 6 | Formatting |
| `keyword_case` | 5 | Formatting |
| `commented_code` | 4 | Remove after proving it is dead |
| `dangerous_statement` | 4 | Two generated pools, kernel call, dynamic table SELECT; track individually |
| `no_chained_assignment` | 4 | Refactor in touched code |
| `select_performance` | 4 | Three `ENDSELECT`/looping reads plus `SELECT *`; review individually |
| `if_in_if` | 3 | Simplify when touched |
| `no_external_form_calls` | 3 | Remove through class extraction |
| `unnecessary_chaining` | 3 | Mechanical cleanup |
| `function_module_recommendations` | 2 | Review released/OO alternatives |
| `line_only_punc` | 2 | Formatting |
| `macro_naming` | 2 | Refactor macros when touched |
| `space_before_dot` | 2 | Formatting |
| `change_if_to_case` | 1 | Readability cleanup |
| `downport` | 1 | Validate on SAP_BASIS 750 |
| `expand_macros` | 1 | Prefer explicit/testable code |
| `line_length` | 1 | Formatting |
| `no_public_attributes` | 1 | Encapsulation cleanup |
| `parser_error` | 1 | ARC lint's older parser rejects a table-valued ABAP Unit assertion that A4H syntax accepts; keep as tool discrepancy until 7.50 validation |

## Initial executable tests

The program now ends with three harmless, short ABAP Unit classes:

- `LTC_QUERY_PARSER`: 8 tests for simple SELECT, default/explicit/unlimited limits, tail clauses, UNION separation, comma syntax, caller `INTO` removal, and missing `FROM` rejection.
- `LTC_LINE_SPLITTER`: 3 tests for short lines, the 255-character boundary, and long-line splitting.
- `LTC_COMMAND_PARSER`: 3 tests for UPDATE, DELETE FROM, and NATIVE quote conversion.

These are characterization tests: they make current behavior explicit without claiming that every behavior is correct. For each open bug, add the smallest failing regression test first, then implement the fix, then refactor while all earlier tests remain green.
