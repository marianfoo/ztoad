# ABAP 7.02 compatibility and abaplint downport evaluation

_Research date: 2026-08-06 · Decision status: do not claim 7.02 support yet_

## Current evidence

The supported floor remains SAP_BASIS 750. A diagnostic run of the current source with abaplint release `v702` found one direct downport item: the existing `VALUE string_table( ... )` expression in an ABAP Unit assertion. A following parser error is a cascade from that expression. The production portion is therefore close to 7.02 syntax according to abaplint, but that is not proof of 7.02 runtime compatibility.

abaplint's [downport rule](https://rules.abaplint.org/downport/) can transform a limited set of newer constructs for `v702`, including inline declarations, constructor operators, table expressions, host escapes, and comma-separated SQL lists. The rule documentation explicitly warns that generated output may not be correct and that only one transformation is performed at a time. The result must therefore be treated as generated code requiring full tests, not as a compatibility guarantee.

## Options

| Option | Evaluation |
|---|---|
| One canonical lowest-compatible source | Preferred if real demand and a live 7.02 system exist. Rewriting the single current test expression may make syntax lint clean, but APIs, DDIC objects, dynpros, GUI classes, and runtime behavior still need live proof. |
| Canonical 7.50 source plus generated 7.02 artifact | Acceptable only if automatic downport becomes necessary and the generated artifact is reproducible, never edited by hand, and activated/tested on 7.02 for every release. |
| Multiple hand-maintained codebases or branches | Not recommended. Fixes and security changes will drift, doubling the already large test matrix and making issue evidence ambiguous. |
| Ship only generated 7.02 code | Not recommended before live validation. It may reduce source syntax while breaking newer systems or hiding transformation defects. |

## Required proof before advertising 7.02

1. Configure an actual SAP_BASIS 702 validation system and record its components and available object types.
2. Make the complete serialized object set install and activate, not only the report source.
3. Run SAP syntax, all ABAP Unit tests, applicable ATC checks, a read-only GUI smoke, and an ST22 delta.
4. Verify all referenced SAP APIs and DDIC objects exist and behave as expected.
5. If a generated artifact is used, compare it to the canonical source semantically and prove deterministic regeneration in CI.

## Recommendation

Keep one canonical codebase and the current 7.50 support promise. It is reasonable to rewrite the isolated `VALUE` test fixture later if that improves portability without reducing readability. Do not introduce a second code line or automated downport release until a live 7.02 target exists and the full object/test matrix is green.
