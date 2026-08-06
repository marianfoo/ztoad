# Plan: reduce the full abaplint inventory to zero

_Status: active · Baseline: 1,857 findings in 57 default rules on 2026-08-06_

## Goal

Reach zero findings under the pinned abaplint default rules without changing intended ZTOAD behavior, then promote the strict full-quality command to required pull-request CI.

## Guardrails

- Keep `npm test` as the current zero-finding compatibility/XML merge gate.
- Use `npm run lint:quality` to recreate the full diagnostic list; do not add its nonzero result to CI yet.
- Never bulk-fix behavior-sensitive rules without characterization tests.
- Keep one issue/one coherent rule batch per pull request and review generated SQL, authorization, data access, and GUI behavior separately.
- Do not suppress findings solely to lower the count.

## Work packages

1. Capture a machine-readable baseline and add a comparison command that fails only on newly introduced findings.
2. Resolve parser errors and prove ABAP 7.50/live syntax parity.
3. Address dangerous statements, SQL escaping/strictness, authorization paths, unchecked return codes, and database-loop findings with security-focused tests.
4. Follow the [test-object extraction TODO](test-object-extraction.md): extract parser, generator, authorization, and editor boundaries into classes and move their tests to native class test includes.
5. Remove obsolete and ambiguous constructs in small reviewed batches.
6. Apply mechanical formatting/naming batches last, with no functional changes.
7. When `npm run lint:quality -- --strict` is green locally and on both SAP targets, add it to `.github/workflows/quality.yml` and make the check required.

## Required evidence per batch

- Before/after full rule counts and no unexplained increase.
- A focused red test for behavior-changing work.
- `npm ci`, `npm test`, and the full diagnostic command.
- SAP_BASIS 750 and S/4HANA 2023 activation, syntax, ABAP Unit, relevant ATC, safe smoke, and ST22 delta.
- Final diff review that separates mechanical changes from behavior changes.
