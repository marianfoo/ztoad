# Migrate the default branch to `main`

_Date: 2026-08-07 · branch: `codex/default-branch-main`_

## Goal

Rename the repository's stable integration/release branch from `master` to
`main` without losing commits, breaking CI or Release Please, invalidating the
open release PR, or leaving local and native-abapGit clients on an obsolete ref.

## Reviewed plan

1. Record the exact starting commit, GitHub default, open PR base, workflow
   filters, merge policy, protection/ruleset state, and native-abapGit branch.
2. Research GitHub's supported rename semantics and Release Please's explicit
   target-branch behavior; record the decision and rollback.
3. Create this migration branch from the exact old default head.
4. Rename the GitHub default branch through the supported API. Verify the new
   default, remote refs, PR #23 base, and absence of a remote `master` branch.
5. Rename the local integration branch, set it to track `origin/main`, refresh
   `origin/HEAD`, and keep this work on the short-lived migration branch.
6. Update current operational instructions, contribution guidance, PR template,
   Quality trigger, Release Please trigger/target/concurrency, active plans, and
   system context. Preserve old branch names in dated research and finished
   plans as historical evidence, with an explicit migration note explaining
   that choice.
7. Switch the A4H native-abapGit repository to `refs/heads/main` and reread it.
   Record that NPL is offline and future ZIPs come from `origin/main`.
8. Run `npm ci`, `npm test`, `git diff --check`, YAML/config parsing, branch-
   reference audits, and a complete diff review. ABAP/live behavior gates are
   not applicable because `src/` and SAP repository objects do not change.
9. Push the migration branch, open a draft PR to `main`, and require the normal
   Quality checks to pass.
10. Audit the first green run and documentation, apply any durable correction,
    archive this plan, and wait for a second green run when the head changes.
11. Squash merge, update local `main`, verify `origin/main` equality and
    `origin/HEAD`, then verify the main-push Quality and Release Please runs.
12. Require one green release PR based on `main`; preserve it unmerged.

## Execution record

- GitHub renamed exact default head
  `b6acc143e09590a48e3fef5b9ac3fda85834de0e` from `master` to `main`.
  `origin/master` no longer exists; local `main` tracks `origin/main`, and
  `origin/HEAD` resolves to `origin/main`.
- GitHub automatically retargeted Release Please PR #23 from `master` to
  `main`, preserving its head and green checks.
- A4H native abapGit repository `000000000017` was switched with full ref
  `refs/heads/main`. A fresh connector read proves that selected branch, and
  the repository check endpoint is green. No pull or activation occurred.
- NPL remains an offline repository; its next reviewed ZIP source is
  `origin/main`.
- `npm ci`, `npm test`, configured abaplint, repository/install contracts,
  `git diff --check`, Node syntax, and YAML parsing are green. The repository
  contract now guards the `main` push filters, Release Please target/concurrency,
  and current operational guidance against branch-name regression.
- The branch-reference audit leaves `master` only in this migration record,
  dated evidence/finished plans, and the README/CHANGELOG phrase "master
  language," which describes localization rather than a Git branch.
- SAP syntax, Unit, ATC, WebGUI, and ST22 are not applicable: no file under
  `src/`, no serialized SAP object, and no live behavior changed.

## Compatibility and risk review

- **ABAP 7.50 / Clean ABAP / Clean Core:** no ABAP or serialized object changes;
  all SAP gates are not applicable with that reason.
- **CI:** pull-request Quality is intentionally branch-agnostic and should run
  on the migration PR; push Quality is changed explicitly to `main`.
- **Release:** an explicit `target-branch: main` avoids relying on default-branch
  inference. PR #23 is never merged during this migration.
- **History:** replacing branch names inside old evidence would make it false;
  only current instructions and active records are updated.
- **Rollback:** follow the reversible rename and configuration procedure in the
  research note before new work diverges from `main`.

## Reference

- [Migration research](../research/2026-08-07-default-branch-main-migration.md)
