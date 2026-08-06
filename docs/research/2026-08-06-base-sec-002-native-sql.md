# BASE-SEC-002 native SQL research

_Date: 2026-08-06 · finding: `BASE-SEC-002`_

## Revalidated vulnerable path

The finding is reachable in the current `master` source:

1. An authenticated ZTOAD user enters `NATIVE <arbitrary database SQL>` in the editor.
2. `QUERY_PARSE_NOSELECT` accepts the command when authorization object `ZTOAD_AUTH` grants activity `16`, or when the fallback `auth_native` flag is enabled.
3. The parser copies the remainder of the user input into `FW_PARAM`, changing only single quotes to double quotes.
4. `QUERY_PROCESS` calls `QUERY_PROCESS_NATIVE` directly.
5. `QUERY_PROCESS_NATIVE` truncates the external statement to 255 characters and passes it to unsupported kernel call `C_DB_EXECUTE` after only a confirmation popup.

The popup is not a security boundary: it neither constrains the database object nor validates statement semantics. A user who can reach this path can submit vendor-specific DDL or DML outside ABAP SQL client handling and outside ZTOAD's normal table-specific authorization checks.

## Security contract

- No SQL statement supplied through the ZTOAD editor may reach a Native SQL API or kernel call.
- `C_DB_EXECUTE` must not exist in repository source.
- `NATIVE` must be rejected even if legacy customization or authorization would previously have enabled it.
- Existing SELECT, INSERT, UPDATE, and DELETE behavior is outside this patch and must remain unchanged.

## Options evaluated

### Replace the kernel call with ADBC

Rejected for this finding. SAP recommends ADBC instead of older Native SQL mechanisms, but also states that SQL text outside operand positions must not originate externally and that operands must use placeholders. Passing the complete editor command to `CL_SQL_STATEMENT` would remove the unsupported call while preserving the injection boundary.

### Add a database-specific allow list

Rejected as disproportionate and incomplete. A safe implementation would need a database-specific grammar, strict object resolution, table-specific authorization, client isolation, placeholder binding, DDL/DML policy, and destructive integration fixtures on both supported database/release targets. A token or regular-expression list would be bypass-prone and would not justify retaining an arbitrary administrative channel in this general SQL viewer.

### Retire the `NATIVE` command

Selected. The feature is already disabled by default, its implementation is unsupported and database-specific, and removing it closes the boundary without changing supported ABAP SQL query behavior. The parser will fail closed for `NATIVE` regardless of the legacy flag, and the executor form/kernel call will be deleted.

## TDD and validation design

- A dependency-free repository contract must fail while `C_DB_EXECUTE` remains and stay in the normal `npm test`/CI path.
- ABAP Unit must prove `NATIVE` is rejected by default and cannot be re-enabled through the legacy fallback flag.
- Existing positive command-parser tests must prove UPDATE and DELETE parsing remain intact.
- A4H must explicitly activate the candidate and pass active syntax, all ABAP Unit tests, ATC review, object/child-part state review, and a safe launch/ST22 delta. No native command will be executed.
- NPL remains ARC-1/ADT-only. Exact ZTOAD validation is blocked while its report/table are absent; no GUI fallback or substitute table is allowed.

## Compatibility, clean core, and release impact

- The patch uses no syntax newer than the SAP_BASIS 750 floor.
- Removing `C_DB_EXECUTE` eliminates the current unsupported-call syntax warning and one direct clean-core violation.
- This is an intentional breaking security change for users who enabled `NATIVE`; it requires a release note.
- Rollback is not recommended because it would reopen arbitrary Native SQL execution. Database administration belongs in purpose-built, audited tooling rather than ZTOAD.

## SAP sources

- [Security Risks Caused by Input from Outside](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENDYNAMIC_PROGRAMMING_SCRTY.html)
- [SQL Injections in Generated Programs](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_INJ_GEN_PROG_SCRTY.html)
- [SQL Injections in Dynamic Tokens](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENSQL_INJ_DYN_TOKENS_SCRTY.html)
- [ABAP Database Connectivity](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENADBC.html)

## Validation result

The focused repository assertion and live ABAP Unit test both failed against the old implementation before production code changed. The final implementation removes the dispatch and executor form, rejects `NATIVE` in `QUERY_PARSE_NOSELECT`, and retains the legacy configuration fields only as ignored layout members.

On A4H/SAP_BASIS 758, explicit activation and active syntax completed with zero errors and three known POSIX warnings; the prior `C_DB_EXECUTE` warning disappeared. All 20 ABAP Unit tests passed. `ABAP_CLOUD_READINESS` improved from 768 findings (463 P1, 305 P2) to 759 (457 P1, 302 P2). Active and inactive main report source had no difference; the seven existing inactive screen/status/text child parts remain `BASE-BUG-007`. A fresh FLP transaction start rendered the editor, reported only missing `STATUS010`, and produced no ST22 delta. No SQL was executed.

The ARC-1 1.0.2 ADT-only probe reached NPL/SAP_BASIS 750 and confirmed that both `PROG ZTOAD` and required `TABL ZTOAD` are absent. Exact 7.50 validation therefore remains prerequisite-blocked without using a GUI or an unfaithful substitute.
