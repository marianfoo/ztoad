# ZTOAD baseline findings

_Snapshot: 2026-08-06 · branch `codex/fix-base-sec-002` · live system A4H client 001, SAP_BASIS 758 SP02 · secondary target NPL client 001, SAP_BASIS 750 SP02_

This is the ordered work list for incremental TDD. It records observed defects separately from broad style debt so a new failure cannot disappear inside the legacy backlog. A finding is closed only after its regression test is green locally where possible, green on A4H, and green on the SAP_BASIS 750 target.

## Baseline evidence

| Gate | Result | Interpretation |
|---|---|---|
| Repository `npm test` | Passed, 0 configured abaplint findings | Fast compatibility/XML gate is green |
| Pinned abaplint default profile | 1,841 findings across 58 rules; pre-fix branch baseline 1,878 | Removing the Native SQL executor reduced diagnostic debt by 37; remaining debt is reproducible locally, not an immediate all-or-nothing gate |
| A4H SAP syntax | 0 errors, 3 warnings | Program compiles on SAP_BASIS 758; the unsupported kernel-call warning is gone |
| A4H ABAP Unit | 20 passed, 0 failed | Parser, generator, command, line-splitting, and editor-policy tests are green |
| A4H ATC `S4HANA_READINESS_2023` | Initial run displayed 0 finding rows | Later evidence shows missing prerequisites; this is not an authoritative zero gate |
| A4H ATC `ABAP_CLOUD_READINESS` | 759 findings: 457 priority 1, 302 priority 2 | Nine findings removed with the Native SQL sink; current classic report remains non-Cloud-compatible |
| A4H WebGUI smoke | Editor startup/input passed; query dispatch blocked | Final editor renders and accepts text without a new dump; installed GUI status `STATUS010` is missing (`BASE-BUG-007`) |
| ABAP 7.50 live gate | ARC-1 lifecycle passed; ZTOAD blocked | `arc-1-750` can create/activate/syntax/unit/delete, but ZTOAD's transparent table is absent and SAP_BASIS 750 cannot create it over ADT |

The BASE-RUN-001 candidate had four normal syntax warnings: three POSIX-regex deprecations plus unsupported `C_DB_EXECUTE`. The BASE-SEC-002 candidate removes the kernel call, leaving only the three known regex warnings.

The BASE-BUG-001 parser/generator baseline remains green inside the current 20-test suite. The current `ABAP_CLOUD_READINESS` result is 759 findings (457 P1, 302 P2). The latest `S4HANA_READINESS_2023` run returned no rows but is incomplete because seven prerequisite checks are unavailable. See the [finished BASE-BUG-001 plan](plans/finished/base-bug-001.md) and the [BASE-SEC-002 research](research/2026-08-06-base-sec-002-native-sql.md) for exact evidence.

## Ordered findings register

Priority meanings: **P0** blocks the requested test workflow or is an immediate security hazard; **P1** should be handled before normal feature expansion; **P2** is planned reliability/design debt; **P3** is mechanical cleanup that should be paid down only in touched code.

| ID | Pri. | Finding and evidence | Test to drive the fix | Status |
|---|---:|---|---|---|
| BASE-RUN-001 | P0 | ZTOAD originally dumped in WebGUI through `DP_PUBLISH_URL`; a rejected SQL-mode spike then dumped in `CL_GUI_SOURCEEDIT`. The final adapter uses `CL_GUI_TEXTEDIT` in WebGUI and keeps `CL_GUI_ABAPEDIT` elsewhere. | Two editor-policy Unit tests plus fresh WebGUI launch/input and post-run ST22 delta. | Fixed candidate: 19/19 green, editor renders and accepts input, no new dump; full query dispatch waits on `BASE-BUG-007` |
| BASE-SEC-001 | P0 | User text becomes dynamic Open SQL and generated ABAP (`GENERATE SUBROUTINE POOL`, lines 2310 and 3657). Parser-derived table/field/tail tokens are not validated through a strict include list. | Malicious/ambiguous table, column, `WHERE`, `HAVING`, subquery, comment, and quoted-keyword cases; verify rejection before generation. | Open |
| BASE-SEC-002 | P0 | Native SQL used unsupported kernel call `C_DB_EXECUTE`. It was a high-impact arbitrary database-command path and produced a live compiler warning. | Default rejection, rejection despite the deprecated enable flag, preserved UPDATE/DELETE parsing, and a no-kernel-call repository contract. | Fixed candidate: local gates green, A4H 20/20 green and warning removed, read-only startup produced no dump; exact NPL gate prerequisite-blocked because PROG/TABL ZTOAD are absent |
| BASE-SEC-003 | P0 | SELECT authorization extraction tokenizes top-level `FROM`/`JOIN` text and can miss nested subqueries/CTEs or concealed data sources. | Multi-table joins, nested subqueries, aliases, comments, quoted identifiers, UNION branches, and unauthorized inner-table cases. | Open |
| BASE-BUG-001 | P1 | [Issue #6](https://github.com/marianfoo/ztoad/issues/6): a reported `SELECT DISTINCT ... COUNT ... MAX ... GROUP BY ... HAVING` query produces “The INTO/APPENDING clause must be at the end of the SELECT.” | Sanitized `DD03L` reproduction; check exact generated ordering around `HAVING`, `ORDER BY`, `UP TO`, and `INTO TABLE`. | Fixed and 17/17 green on A4H; live 7.50 pending |
| BASE-BUG-002 | P1 | [Issue #7](https://github.com/marianfoo/ztoad/issues/7): a reported `SUM( CASE ... END ) AS ...` over `EKBE` produces “No component exists with the name CASE.” The expression is split into false result components. | Sanitized aggregate with multi-line `CASE`, qualified fields, multiplication, alias, WHERE, and GROUP BY; assert one aggregate expression and the expected generated row type. | Open |
| BASE-BUG-003 | P1 | [Issue #4](https://github.com/marianfoo/ztoad/issues/4): `SUBSTRING`/`CONCAT` produce “No component exists with the name SUBSTRING(”, exposing naïve select-list tokenization. | Nested function arguments, commas inside functions, aliases, literals containing spaces/commas, and function composition. | Open |
| BASE-BUG-004 | P1 | Keyword detection uses string searches and space splitting rather than quote/parenthesis-aware lexical tokens. Keywords in literals, comments, functions, or subqueries can move clause boundaries. | Quoted `FROM`, `WHERE`, `UNION`, `UP TO`; escaped quotes; comments; nested parentheses; multiline queries. | Open |
| BASE-BUG-005 | P1 | `UNION` splitting is whitespace-sensitive and does not model `UNION ALL`; branches are appended while assuming compatible result layouts. | `UNION`, `UNION ALL`, mismatched branch types/columns, per-branch limits, and keywords in literals/subqueries. | Open |
| BASE-BUG-006 | P1 | [Issue #2](https://github.com/marianfoo/ztoad/issues/2): no serialized `TRAN ZTOAD` existed, so FLP/WebGUI could not launch a stable ZTOAD transaction directly. | Repository contract, native-abapGit round trip, direct FLP and standalone WebGUI launch, ST22 delta, and ADT-only 7.50 availability check. | Fixed candidate: local contract green; native A4H object clean; both launch paths reach ZTOAD with no new dump. Exact NPL install remains prerequisite-blocked because all ZTOAD objects are absent. |
| BASE-BUG-007 | P1 | [Issue #5](https://github.com/marianfoo/ztoad/issues/5): source-only/manual installation is incomplete. A4H currently reaches screen 0010 but reports missing GUI status `STATUS010` even though repository `ztoad.prog.xml` serializes it; complete ZTOAD also needs its dynpros, TABL, and SUSO. | Fresh-package native-abapGit install test verifying all serialized objects and GUI metadata activate, `STATUS010` exists, and the first read-only query can be dispatched. | Open; currently blocks full A4H query smoke |
| BASE-RUN-002 | P1 | Generated-program failures are not isolated into a stable error contract; dumps or generated source can leak query details. | Syntax/runtime exception tests with sanitized error output and no ST22 dump for expected bad input. | Open |
| BASE-RUN-003 | P1 | The generated subroutine-pool approach has a finite per-session pool budget and encourages session restart behavior instead of bounded execution objects. | Repeated-query stress test across the documented maximum, checking graceful handling and cleanup. | Open |
| BASE-RUN-004 | P1 | `UP TO 0 ROWS` means unlimited results. A user can accidentally run an unbounded query or expensive aggregation in an interactive tool. | Row-limit policy tests, explicit unlimited confirmation/policy test, timeout/load test on disposable data. | Open |
| BASE-RUN-005 | P1 | INSERT parsing is quote- and whitespace-sensitive and relies on dynamic component assignment/conversion. Truncation, missing fields, and conversion failures need a defined result. | Values/SET variants, embedded quotes, numeric/date conversion, too-long values, missing/duplicate fields; isolated Z table only. | Open |
| BASE-ARCH-001 | P2 | The report is over 5,000 lines with 37 lint findings for procedural-size reduction. GUI, parser, authorization, generator, and execution responsibilities are coupled. | Preserve characterization tests; extract one pure parser/generator class per fixed issue without a big-bang rewrite. | Open |
| BASE-ARCH-002 | P2 | GUI-bound globals and `FORM` routines prevent headless tests for startup, editor selection, authorization, and execution orchestration. | Introduce narrow editor/auth/executor interfaces; test factories and orchestration with doubles. | Open |
| BASE-ARCH-003 | P2 | Report-local ABAP Unit tests cannot be distributed separately, while an arbitrary second test report would lose native access/discovery. | Follow the [test-object extraction TODO](plans/test-object-extraction.md): extract cohesive global classes and move tests to native class test includes incrementally. | TODO |
| BASE-CLEAN-001 | P2 | Clean-core status is provisionally Level D/unknown because of `CL_GUI_ABAPEDIT`, DDIC internals such as `DD03L`, system/kernel calls, and other unreleased references. Classic controls such as `CL_GUI_ALV_GRID` are Level B on-premise APIs. | Replace/encapsulate unsupported and unknown references, then re-run released-API ATC and document accepted Level B dependencies. | Open |
| BASE-TOOL-001 | P2 | ARC-1 0.9.19 can list/check this native-abapGit repository but its clone call sends an XML shape rejected by A4H 758 (`repository` namespace mismatch). Native abapGit UI was required to link/pull. | Minimal ARC-1 integration reproduction against A4H 758; fix ARC-1 separately, keep UI fallback documented. | Open |
| BASE-ENV-001 | P2 | NPL and `arc-1-750` are configured and the ADT report lifecycle is proven, but exact ZTOAD validation is blocked because transparent table `ZTOAD` is absent and SAP_BASIS 750 has no ADT transparent-table create endpoint. | After the real table is provisioned outside the current ADT-only boundary, create/update the report and run activation, syntax, Unit, and ATC through ARC-1. NPL UI smoke is out of scope. | Partially complete; prerequisite blocked |
| BASE-TOOL-002 | P2 | ARC-1 1.0.2 detects NPL release 750, but its lint inventory reports `v702`/unknown; absent `PROG ZTOAD` is misclassified as a class-local include, and nonexistent `DEVC ZTOAD` returns unrelated objects. | Add focused ARC-1 integration reproductions on NPL and correct release propagation, not-found hints, and package resolution in the ARC-1 project. | Open |
| BASE-TOOL-003 | P2 | The local A4H ARC-1 pre-write linter also selected ABAP v702 and rejected valid 7.50+ syntax. The live SAP preflight accepted the exact source, and A4H activated it with zero syntax errors. | Propagate probed/configured SAP release into pre-write lint. Until fixed, bypass only `lintBeforeWrite` after repository abaplint is green; retain live preflight, explicit activation, syntax, Unit, and object-state checks. | Open |
| BASE-REL-001 | P2 | Source declares 4.0.4 but the latest Git tag is 4.0.3. Release Please uses 4.0.4 as its manifest baseline, but its first compare link expects that tag. | After both live gates pass at an exact commit, decide whether to create the one-time immutable 4.0.4 tag/release. | Decision |
| BASE-CTS-001 | P3 | Setup left empty local request `A4HK906377`; active work is in `A4HK906379`. | Manual owner decision whether to retain or delete the empty request. No automated deletion. | Decision |

## Full lint debt by rule

This diagnostic profile is intentionally not the merge gate yet. Run `npm run lint:quality` to print the complete current per-rule list from the pinned CLI. New code must not add unexplained findings, and touched code should reduce relevant counts without mass-formatting unrelated lines. The raw default profile contains a configuration conflict: `method_parameter_names` requires Hungarian-style direction/type prefixes while `no_prefixes` rejects those same prefixes. The future strict profile must resolve that conflict explicitly in favor of the selected Clean ABAP convention; suppressing individual findings just to lower the count is not acceptable. The counts, prioritization, and promotion-to-CI criteria are maintained in the [research report](research/2026-08-06-abaplint-quality-roadmap.md) and [active zero-findings plan](plans/abaplint-zero-findings.md).

## Initial executable tests

The program now ends with five harmless, short ABAP Unit classes:

- `LTC_QUERY_PARSER`: 8 tests for simple SELECT, default/explicit/unlimited limits, tail clauses, UNION separation, comma syntax, caller `INTO` removal, and missing `FROM` rejection.
- `LTC_QUERY_GENERATOR`: 3 tests for strict aggregate clause ordering plus escaped-count and legacy-select compatibility.
- `LTC_LINE_SPLITTER`: 3 tests for short lines, the 255-character boundary, and long-line splitting.
- `LTC_COMMAND_PARSER`: 4 tests for UPDATE, DELETE FROM, default Native SQL rejection, and rejection despite the deprecated enable flag.
- `LTCL_EDITOR_CONFIGURATION`: 2 tests selecting the supported WebGUI text editor while retaining the desktop ABAP editor.

These are characterization tests: they make current behavior explicit without claiming that every behavior is correct. For each open bug, add the smallest failing regression test first, then implement the fix, then refactor while all earlier tests remain green.
