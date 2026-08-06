# BASE-SEC-001 plan: prevent generated ABAP injection

_Date: 2026-08-06 · branch: `codex/fix-base-sec-001`_

## Goal

Prevent parser output from escaping the intended SQL statement and becoming additional ABAP in a generated subroutine pool, without removing the supported SQL workbench surface.

## Patch contract

- Vulnerable path: editor input → procedural parser fragments → `QUERY_GENERATE` / `QUERY_GENERATE_NOSELECT` → `SYNTAX-CHECK FOR` → `GENERATE SUBROUTINE POOL` → later execution.
- Attacker prerequisite: a crafted fragment reaching either generator. The current editor usually strips a top-level period, so exact end-to-end UI reachability is reduced but not accepted as the generator's security boundary.
- Invariant: every emitted user-derived fragment remains inside one intended ABAP SQL statement; source terminators/comments/host references and unsupported literal forms fail before generation.
- Preserved behavior: covered SELECT/DML syntax, SQL identifiers/functions/operators, single-quoted and decimal/negative literals, parser-stripped `INTO`, SAP_BASIS 750 syntax, and existing authorization decisions. ABAP type namespaces fail closed until they can be recognized in a grammar-aware CAST position.
- Out of scope: native SQL retirement (`BASE-SEC-002`), nested-source authorization (`BASE-SEC-003`), complete SQL grammar/parser redesign, and adding a new per-column authorization model.

## Reviewed sequence

1. Trace both generated-program paths and compare SAP guidance for generated code and external ABAP SQL tokens.
2. Add harmless generator regressions proving that old SELECT and UPDATE code accepts a valid statement-injection payload. Generate but never execute the pool; deploy the test-only source to A4H and record red.
3. Review the plan for include-list completeness, false positives, literal/decimal handling, 7.50 compatibility, Clean ABAP/Clean Core, and independence from SEC-002/SEC-003.
4. Add a pure local input validator at the last shared pre-generation boundary. Use a positive character include list plus explicit single-quote, decimal-period, numeric-minus, and whitespace rules.
5. Guard both generators, clear the output program on rejection, return safely from the non-SELECT caller, and add focused validator unit tests for valid and invalid boundaries.
6. Run `npm ci`, `npm test`, `npm run lint:quality`, `git diff --check`, exploit reversion review, and a complete diff/security review.
7. Deploy the exact candidate to A4H through ARC-1, explicitly activate, and run active syntax, all ABAP Unit tests with coverage, active/inactive comparison, inactive-child inventory, and both recorded ATC variants.
8. Start a fresh A4H transaction with no SQL execution and verify the ST22 delta; retain missing `STATUS010` as `BASE-BUG-007`.
9. Probe NPL through ARC-1/ADT only and record the existing missing-object prerequisite without GUI fallback.
10. Update the finding register, open a draft PR, require first green CI, audit the workflow and implementation, apply useful process improvements, finish this plan, and require final green CI.

## Plan review

- The failing regressions exercise the real generator boundary and prove exploitability without executing injected code or touching data.
- Validation after parsing preserves the safe removal of caller-provided `INTO` targets and avoids treating characters inside SQL literals as ABAP source.
- A positive character policy is easier to audit than an ABAP-keyword deny list. Explicit decimal/minus rules preserve common numeric predicates without allowing a general statement terminator or `sy-uname` form; an adversarial `ABAP.<word>` lookalike remains rejected rather than creating a context-free period exception.
- Guarding both generators avoids a SELECT-only fix while leaving native SQL wholly owned by SEC-002.
- The local class is cohesive and pure; replacing the generic pool architecture remains a later structural change.

## Evidence log

- Baseline restore: A4H explicitly restored to master source SHA-256 `f30e88b6e0a52fd15d6fdaf09e383b22629bb069c55317a7d9a2e9c565cf8694`; activation has the four known warnings and 19/19 ABAP Unit tests pass.
- SAP Docs MCP: generic generated programs are the least safe dynamic technique; external SQL table/column/condition tokens require include-list checks and external values must be escaped or bound.
- ABAP Unit red: the test-only source activated on A4H with the four known warnings. Exactly the two exploit regressions failed because both generators returned a valid subroutine-pool name: `LTC_QUERY_GENERATOR.REJECTS_STATEMENT_INJECTION` and `LTC_COMMAND_PARSER.REJECTS_DML_INJECTION`. The other 19 tests passed. Coverage was 17.01% statements, 13.94% branches, and 7.89% procedures. Neither pool was executed and no SQL ran.
- Implementation/local/A4H/NPL/CI: pending.
