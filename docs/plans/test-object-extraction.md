# TODO: move ABAP Unit tests to class test includes

_Status: TODO · Priority: P2 · Tracking ID: BASE-ARCH-003_

## Goal

Move the report-local ABAP Unit tests out of `ZTOAD` as production parser, generator, authorization, and editor logic is extracted into global classes. Store each class's tests in its native class test include so abapGit serializes production and test sources separately.

Do not create a second arbitrary executable test report. The separation must preserve standard ABAP Unit discovery and must not introduce public or test-only production entry points.

## Prerequisites

- Keep the current report-local characterization tests green until their production boundary is extracted.
- Add focused red tests for the issue being fixed before moving its code.
- Create global classes and their test includes in SAP, then round-trip the structural objects through native abapGit; do not construct serializer XML manually.
- Validate fixture and API availability on SAP_BASIS 750 and S/4HANA 2023.

## Work sequence

1. Extract the query parser and generator behind small, typed class APIs while retaining the report as the orchestration boundary.
2. Move the corresponding local tests into native class test includes and prove behavioral parity.
3. Extract authorization and execution boundaries with interfaces and test doubles.
4. Extract the editor/startup boundary needed to test browser-safe behavior without a frontend control.
5. Remove each migrated report-local test only after its class test is green locally and on both live targets.
6. Document which production object files a manual installer needs and which `*.clas.testclasses.abap` files are optional for runtime use.

## Acceptance criteria

- All existing and newly added tests remain discoverable through standard ABAP Unit runs.
- The complete suite passes locally, on SAP_BASIS 750, and on S/4HANA 2023.
- abapGit stores class production and test-include sources separately.
- Production code has no public API added solely for tests.
- A manual production-only installation path is documented and tested without maintaining a second source codebase.
- Relevant procedural and external-`FORM` abaplint/ATC findings decrease with no unexplained new finding.

This TODO is intentionally incremental. It should be implemented alongside focused parser/generator and startup issues, not as one big-bang rewrite.
