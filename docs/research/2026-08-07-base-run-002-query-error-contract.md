# BASE-RUN-002: generated-query error contract

_Observed 2026-08-07 on SAP_BASIS 750 and reviewed against the current generated SELECT and DML paths. Test values are synthetic and contain no system, credential, or business data._

## Reproduction

ZTOAD has two generated-program failure boundaries:

1. `QUERY_GENERATE` and `QUERY_GENERATE_NOSELECT` collect the technical text from `SYNTAX-CHECK` and display that text verbatim when execution was requested.
2. `QUERY_PROCESS` calls `RUN_SQL` in the temporary subroutine pool directly. There is no exception boundary between user-derived generated code and the dialog/report orchestration.

The red candidate `1c1e748c691a44f95302b11977fa5a497abbeeee` preserves those behaviors behind narrow test seams. Its local source SHA-256 is `c229760c182c549572c96b6a3ab7b16fd60631ce6891b054f69df074177637ee`; NPL reported equal active/inactive source at server-normalized SHA-256 `14889ac1eaecfc101921e625649a7bcd087d4daaa7fae8638de1e719644fb9e0` and no syntax error.

The 108-test red replay produced exactly two focused failures:

- `LTCL_QUERY_EXECUTION->CONTAINS_RUNTIME_EXCEPTION` showed `COMPUTE_INT_ZERODIVIDE` escaping the generated-program execution boundary.
- `LTCL_QUERY_EXECUTION->SANITIZES_TECHNICAL_DETAIL` received `Compiler detail contains SECRET_QUERY_VALUE` instead of the existing generic `Cannot parse the query` text.

The NPL dump list remained unchanged; the ABAP Unit harness contained the deliberate red exception. A disposable spike then placed `TRY ... CATCH CX_ROOT` directly around the external `PERFORM`; 107/108 tests passed and only the intentionally unchanged sanitizer test remained red. The spike was removed and NPL was returned to the exact two-test red candidate before implementation planning.

## Official SAP contract

SAP documents that a catchable exception which is handled with `TRY ... CATCH ... ENDTRY` does not become a runtime error. A `CATCH` for a superclass also handles its subclasses. This supports one narrow `CX_ROOT` boundary around the generated routine without inspecting or displaying the exception object.

SAP also documents a different contract for `GENERATE SUBROUTINE POOL`:

- syntax errors initialize the returned program name and set `sy-subrc`;
- generation errors are handled internally and set `sy-subrc = 8`, but SAP still records a short dump and performs a rollback;
- a session can hold at most 36 temporary subroutine pools;
- temporary pools cannot be explicitly deleted.

Therefore this finding can prevent dumps from expected _catchable execution_ failures and sanitize compiler/runtime output, but it cannot honestly promise that every possible generation or uncatchable runtime failure is dump-free. Avoiding the finite-pool generation error belongs to `BASE-RUN-003`.

Primary references:

- [SAP `CATCH` keyword documentation](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPCATCH_TRY.html)
- [SAP ABAP language exceptions](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENABAP_LANGUAGE_EXCEPTIONS.html)
- [SAP runtime errors and short dumps](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENNONCAT_EXCEPTIONS.html)
- [SAP `PERFORM ... IN PROGRAM`](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPPERFORM_FORM.html)
- [SAP `GENERATE SUBROUTINE POOL`](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPGENERATE_SUBROUTINE_POOL.html)
- [SAP generation-error additions](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABAPGENERATE_SUBR_ERROR_HANDLING.html)

## Root cause

The report treats an external, user-derived temporary program like an internal trusted subroutine. Technical diagnostics are also used as UI text. These two concerns are coupled into the large procedural orchestration, so failures either cross into ABAP Unit/dialog processing or reveal compiler-selected query tokens.

The problem is not that a specific database exception class is missing from a list. The generated program can raise many class-based failures: database, conversion, arithmetic, dynamic-call, and future parser/generator defects. A narrow catch at the trust boundary is more stable than a growing exception allow-list. The exception text must not be called or logged because it can contain query fragments or values.

## Recommended contract

- Execute the generated routine through one FORM boundary because external `PERFORM` is not allowed in ABAP Objects methods on the 7.50 floor.
- Catch `CX_ROOT` only around that external call, clear partial output values, and return a boolean failure result.
- Convert technical compile/generation/runtime details to the existing translatable generic text. Do not expose the exception object, compiler word, line, generated source, or submitted query in the error message.
- Keep **Show generated code** as an explicit diagnostic action for the same user; it is not an automatic failure response. Document that it intentionally displays the submitted query.
- Check `sy-subrc` after both `GENERATE SUBROUTINE POOL` calls and clear the program handle on any failure. This makes the return contract stable, while `BASE-RUN-003` remains responsible for preventing the documented pool-full dump.
- On failure, do not display a result, report success, or persist the query to history.

## Acceptance boundary

ABAP Unit must cover the deterministic catchable runtime failure, generic error conversion, unchanged successful execution, and empty partial outputs. Existing invalid SELECT/DML syntax tests continue to prove that compiler rejection returns no program. Live acceptance requires exact activation, syntax, all tests, ATC comparison, and inactive-object checks on 750 and 758. A fresh A4H browser session must submit a sanitized read-only statement that fails at runtime, show only the generic error, and add no ST22 entry; a normal read-only query must still produce its result.

## Implemented candidate and validation

Frozen source commit `92946feb19a97925851fe8e34ecb3a2b7e75085c` has local SHA-256 `ff7c4ba0f78a87605b61713e50a0d81db698485343e084b498e8868953038fd8`. Both SAP targets reported equal active/inactive source at server-normalized SHA-256 `7af6d81a2eedd2c0f61459a9e35c72f1d394da06b516e9e6dc20d51ce8db4136` and no inactive ZTOAD part.

- NPL: active syntax had no finding; all 109 Unit tests passed; complete `DEFAULT` ATC returned 85 findings (3 P1, 4 P2, 78 P3), one fewer P3 than the 106-test master baseline; the focused Unit run added no dump.
- A4H: active syntax had no error and the seven known POSIX warnings; all 109 Unit tests passed; complete `ABAP_CLOUD_READINESS` returned 709 findings (490 P1, 219 P2); `S4HANA_READINESS_2023` remained incomplete because prerequisite evidence was unavailable.
- Fresh A4H WebGUI: real typing plus blur submitted the sanitized read-only failure probe `SELECT COUNT( * ) FROM T000 WHERE DIV( 1, 0 ) = 0`. The visible UI returned only `Cannot parse the query`, with no technical detail or result. A following `SELECT MANDT FROM T000` returned the three expected client rows and a success status. The complete recent ST22 ID set remained 49 before and after.

The permanent containment regression supplies a nonexistent generated-program handle, which raises at the same external `PERFORM` boundary without allocating another temporary pool. The earlier red arithmetic fixture and the live divide-by-zero probe demonstrate an exception originating inside generated execution. This representation change avoids adding pool-consumption debt to the failure test while preserving the boundary invariant.

After evidence, both shared systems were restored to master `a5ad27cc73a50101441bc2a0c0767108bc25a2fc`. Each target then had equal active/inactive source at server-normalized SHA-256 `202d9d40626428ab051a36de70180985da4e845a67e237d43e1036060db9ed4e`, 106/106 Unit, and no inactive ZTOAD part; NPL syntax was clean and A4H retained only its seven known POSIX warnings.
