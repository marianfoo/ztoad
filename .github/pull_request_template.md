## Goal

<!-- Link the issue and explain the user-visible result. -->

## Plan and red evidence

<!-- Link docs/plans/<finding>.md and state how the original implementation failed the focused test. -->

## Validation

- [ ] `npm ci` and `npm test` pass locally.
- [ ] Serialized files were produced or verified with native abapGit; XML was not hand-authored without a system round trip.
- [ ] Native abapGit staging contained only intended objects; unrelated system/Git drift was documented and left unselected.
- [ ] ABAP 7.50: pull, activation, syntax check, ABAP Unit, and ATC pass, or this is not applicable and is explained below.
- [ ] S/4HANA 2023: pull, activation, syntax check, ABAP Unit, and ATC pass, or this is not applicable and is explained below.
- [ ] Activation evidence covers affected child parts (screens, GUI statuses, text elements, and includes), not only main-source equality.
- [ ] A safe manual ZTOAD smoke test passes on both systems, or the omitted system/check is explained below.
- [ ] ST22 was checked before/after live smoke; known and new dumps are distinguished.
- [ ] ATC prerequisite/check errors were reviewed; an incomplete run is not reported as zero findings.
- [ ] Authorization and SQL-injection implications were reviewed.
- [ ] New or changed logic has ABAP Unit coverage where technically feasible.
- [ ] Documentation and changelog impact were considered.

## Test evidence / exceptions

<!-- Record system releases, ATC variant, test results, and justified omissions. Do not paste credentials or business data. -->

## Final review and process audit

<!-- Summarize the final diff/security review, first green CI run, process improvements, and second green CI run. -->

## Release note

<!-- Use a Conventional Commit PR title: fix:, feat:, docs:, refactor:, test:, ci:, or chore:. -->
