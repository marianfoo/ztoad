# Plan: reduce the full abaplint inventory to zero

_Status: active · Initial baseline: 1,857 findings in 57 default rules on 2026-08-06 · integrated default-branch `2360fe4` checkpoint: 2,051 findings in 61 rules on 2026-08-07_

## Goal

Reach zero findings under a pinned, internally coherent strict abaplint profile without changing intended ZTOAD behavior, then promote that profile to required pull-request CI. Keep the raw default-rule inventory reproducible as a broad discovery report, but do not define an impossible gate from mutually contradictory default configurations.

## Guardrails

- Keep `npm test` as the current zero-finding compatibility/XML merge gate.
- Use `npm run lint:quality` to recreate the full diagnostic list; do not add its nonzero result to CI yet.
- Resolve rule-configuration contradictions explicitly and document the selected Clean ABAP convention. In particular, the defaults for `method_parameter_names` require Hungarian prefixes while `no_prefixes` rejects the same prefixes; the strict profile should keep the no-prefix convention and configure or remove the redundant conflicting naming rule.
- Never bulk-fix behavior-sensitive rules without characterization tests.
- Keep one issue/one coherent rule batch per pull request and review generated SQL, authorization, data access, and GUI behavior separately.
- Do not suppress findings solely to lower the count.

## Work packages

1. Capture a machine-readable raw baseline and add a comparison command that reports newly introduced findings without pretending contradictory naming defaults can reach zero.
2. Define and review the coherent strict profile, selecting Clean ABAP no-prefix naming and documenting every deviation from raw defaults.
3. Resolve parser errors and prove ABAP 7.50/live syntax parity.
4. Address dangerous statements, SQL escaping/strictness, authorization paths, unchecked return codes, and database-loop findings with security-focused tests.
5. Follow the [test-object extraction TODO](test-object-extraction.md): extract parser, generator, authorization, and editor boundaries into classes and move their tests to native class test includes.
6. Remove obsolete and ambiguous constructs in small reviewed batches.
7. Apply mechanical formatting/naming batches last, with no functional changes.
8. When the coherent strict command is green locally and on both SAP targets, add it to `.github/workflows/quality.yml` and make the check required.

## Required evidence per batch

- Before/after full rule counts and no unexplained increase.
- A focused red test for behavior-changing work.
- `npm ci`, `npm test`, and the full diagnostic command.
- SAP_BASIS 750 and S/4HANA 2023 activation, syntax, ABAP Unit, relevant ATC, safe smoke, and ST22 delta.
- Final diff review that separates mechanical changes from behavior changes.
