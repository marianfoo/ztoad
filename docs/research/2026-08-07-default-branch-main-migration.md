# Default branch migration from `master` to `main`

_Researched: 2026-08-07_

## Starting state

- GitHub default branch: `master` at `b6acc143e09590a48e3fef5b9ac3fda85834de0e`.
- Repository branch protection and repository rulesets: none.
- Merge policy: squash only; merged branches are deleted automatically.
- Release Please PR #23 targets `master` and is green at version `5.0.1`.
- Quality runs for every pull request and for pushes to `master`.
- Release Please runs for pushes to `master` and by manual dispatch.
- The shared online A4H native-abapGit repository uses the full branch ref
  `refs/heads/master`. NPL uses an offline ZIP repository and has no online
  branch to switch.

## Authoritative behavior

GitHub documents two related operations: changing the default to another
existing branch and renaming a branch. Renaming the default branch is the safer
fit here because GitHub updates the default branch, open pull-request bases,
branch-protection policies, and normal repository URL redirects together.
Collaborators must still update local tracking, and raw-content URLs do not
redirect.

GitHub also states that Actions workflow references are not rewritten by a
branch rename. ZTOAD must therefore change both workflow push filters itself.
Release Please documents `target-branch` as the branch against which it opens a
release PR; setting it explicitly to `main` removes ambiguity after the rename.

Sources:

- [GitHub: Renaming a branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/renaming-a-branch)
- [GitHub: Changing the default branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/changing-the-default-branch)
- [Release Please Action inputs](https://github.com/googleapis/release-please-action#action-inputs)

## Migration decisions

1. Create the migration branch from the exact old default head.
2. Rename the GitHub branch through the supported API, then update the local
   integration branch and `origin/HEAD` using GitHub's documented commands.
3. Update Quality and Release Please to use `main`; configure Release Please's
   target explicitly and rename its concurrency group.
4. Update current operational documentation and templates. Do not rewrite
   dated research or finished plans whose `master` references are historical
   evidence from before this migration.
5. Verify that PR #23 follows the new base. After the migration reaches `main`,
   run Release Please and require one current green release PR. Do not merge the
   release PR as part of the branch migration.
6. Switch the online A4H abapGit repository with the full ref
   `refs/heads/main` and reread it to prove the postcondition. NPL's next
   reviewed offline ZIP must be generated from `origin/main`.

The switch was performed through a bounded ARC-1 1.0.2 process after an
explicit feature probe. The first cold-process call returned `isError: true`
and made no change; the persistent probe/switch sequence returned `ok: true`.
A separate fresh `list_repos` read then reported repository `000000000017` on
`refs/heads/main`, and the abapGit check endpoint returned `ok: true`. Switching
the selected ref did not pull or activate SAP objects.

## Validation and rollback

This is a GitHub/tooling/documentation migration. It changes no ABAP source,
serialized SAP object, or live behavior, so SAP syntax, Unit, ATC, browser, and
ST22 gates are not applicable. The repository's local and GitHub Quality gates
remain mandatory.

Validation requires:

- GitHub and `origin/HEAD` report `main` as the default;
- `origin/main` and local `main` identify the same commit;
- no remote `master` branch remains after the rename;
- a pull request to `main` receives the normal Quality checks;
- a push/dispatch on `main` runs Release Please against `main`;
- the release PR is green and has one unambiguous base;
- the A4H native-abapGit repository reports `refs/heads/main` after a fresh read.

If the migration must be rolled back before dependent work starts, use the same
GitHub rename operation from `main` to `master`, restore the workflow filters and
Release Please target in a reviewed change, restore local tracking and
`origin/HEAD`, and switch A4H abapGit back with the verified full ref.
