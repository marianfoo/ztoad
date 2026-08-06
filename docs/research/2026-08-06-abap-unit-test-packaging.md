# ABAP Unit packaging for ZTOAD

_Research date: 2026-08-06 · Decision status: recommended direction recorded_

## Question

Can the ABAP Unit tests be moved out of `ZTOAD` so a manual installer can copy only the production report, while abapGit users still receive the complete test suite?

## Evidence

- ABAP Unit test code belongs in local test classes and is not executed as productive application code. SAP supports special test includes, but ordinary report programs cannot currently create such an include; the special mechanism is available for class pools and function groups. See SAP's [test include glossary](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENTEST_INCLUDE_GLOSRY.html) and [ABAP Unit overview](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/ABENABAP_UNIT.html).
- For a global class, abapGit serializes the class implementation and its local test classes separately, including `*.clas.testclasses.abap`. See the official [abapGit file formats](https://docs.abapgit.org/development-guide/serializers/file-formats.html).
- The current tests call report-local `FORM` routines and use report globals. A separate executable test report would either lose access to those internals or require new public/test-only entry points.

## Options

| Option | Evaluation |
|---|---|
| Keep tests at the end of the report | Recommended now. It uses native ABAP Unit discovery, keeps each characterization test with the exact legacy boundary, and requires no test-only production API. Manual copiers receive extra inactive test code, not a second runtime dependency. |
| Create a separate arbitrary test report | Not recommended. It weakens the native relationship to the code under test, needs installation ordering and public seams, and is less discoverable in standard ABAP Unit runs. |
| Extract production logic to global classes | Recommended target architecture. abapGit then stores production and `testclasses` sources separately while SAP retains native test discovery. This also removes the two ABAP Cloud warnings caused by tests calling legacy `FORM`s. |
| Publish a generated source-only distribution | Useful later for manual installation, but it must be generated from the canonical abapGit state and clearly state that screens, table, authorization object, and transaction metadata are still required. It is not a substitute for a supported complete installation. |

## Decision

Keep the current report-local tests while fixing issues incrementally. When a parser/generator area is next refactored, extract a cohesive global class and move its tests into the class test include. Do not create a second hand-maintained test report merely to make the manual copy shorter.

For users who need a reduced download, add a generated source-only artifact only after the complete object dependencies and limitations are documented and tested. Native abapGit remains the supported installation path.
