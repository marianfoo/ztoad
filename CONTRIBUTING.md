# Contributing to ZTOAD

ZTOAD is an abapGit repository for a classic executable ABAP report with screens, text elements, a transparent table, and an authorization object. A copied `.prog.abap` file is therefore not a complete installation.

## Local setup

Install Node.js 18 or newer, clone the repository, and run:

```sh
npm ci
npm test
```

The pinned abaplint version parses the abapGit files, checks serializer consistency, and enforces the ABAP 7.50 syntax floor. No SAP credentials are needed for local checks.

## Develop a change

1. Open or link an issue. Bug reports should contain a minimal sanitized query, exact error, ZTOAD version, SAP_BASIS/support-package level, and database.
2. Select one ID from [docs/baseline-findings.md](docs/baseline-findings.md) or add a new finding. Start a short-lived branch from current `main`; keep red evidence on that branch and never merge a known-red state.
3. Add a focused failing regression test before changing production behavior. Follow the full [TDD strategy](docs/test-strategy.md).
4. For source-only changes, edit the serialized ABAP source locally. For a new object, screen, transaction, DDIC definition, or other structural metadata, make the change in a development SAP system and export it with native abapGit.
5. Make the smallest fix, run `npm test`, and perform the two live-system gates described below.
6. Commit with a Conventional Commit subject such as `fix: parse CASE expressions in aggregates` or `feat: add transaction code`. Push the short-lived branch, open a pull request to `main`, require green checks, and squash merge with a Conventional Commit title.

Do not hand-author abapGit XML for a new or structurally changed SAP object. The serializer output is release- and object-type-sensitive; let native abapGit generate it, then review it in Git.

## Live validation

Test the exact candidate based on current `main` on both targets, in this order:

1. ABAP 7.50: native-abapGit pull or controlled ARC-1 source deployment, activation, syntax, ABAP Unit, ATC, safe manual ZTOAD smoke test, and ST22 delta check.
2. S/4HANA 2023: repeat the same checks and watch for behavior changes in the newer ABAP SQL parser/runtime.

Record the system release, ATC variant, and result in the pull request. Never paste credentials or business data. The complete procedure and ARC-1 commands are in [docs/development.md](docs/development.md).

## Commit and release conventions

Release Please derives versions and release notes from squash commits on `main`:

- `fix:` → patch release
- `feat:` → minor release
- `feat!:` or a `BREAKING CHANGE:` footer → major release
- `docs:`, `test:`, `ci:`, `refactor:`, and `chore:` describe non-release work unless the commit includes a releasable footer

Every change uses a pull request and squash merge so its title becomes one deliberate release-note entry. Release Please updates a separate release PR; merging that release PR creates the GitHub tag and release.
