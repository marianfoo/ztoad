# BASE-DDIC-001 enhancement-category plan

_Created: 2026-08-07 · finding: `BASE-DDIC-001` · target branch: `codex/fix-base-ddic-001`_

## Objective

Remove the offline-install warning and persistent table drift by declaring table `ZTOAD` as `#NOT_EXTENSIBLE` and round-tripping the structural metadata through native abapGit.

## Red evidence and test

- `src/ztoad.tabl.xml` has no `DD02V-EXCLASS` element.
- Both live systems report `#NOT_CLASSIFIED`; the NPL offline pull warned that the enhancement category was missing.
- Add a repository contract requiring the native-abapGit value `<EXCLASS>1</EXCLASS>`. Replay it against the current XML and record the intended red failure before changing the table.
- Red replay: `npm run test:repository` exits 1 at the focused `DD02V-EXCLASS 1` assertion; the existing launcher and forbidden-kernel-call assertions are reached first and remain green.

## Implementation

1. Commit and push the red contract plus this reviewed plan so the coordinated native-abapGit branch exists remotely.
2. On A4H, refresh/check the shared repository while it is still on `refs/heads/master`, record all drift, then switch using the full feature ref and verify the selected branch with a fresh read.
3. Change only the active table annotation to `#NOT_EXTENSIBLE` through ARC-1, explicitly activate `TABL ZTOAD`, and confirm its fields and technical properties are unchanged.
4. Refresh native abapGit, stage only `TABL ZTOAD`, review the exact object/file diff, push it to the feature branch, and fetch the resulting serializer commit locally. Never select the package or use **Add All**.
5. Restore the shared A4H repository with the full `refs/heads/master` ref, verify the branch and clean state, and explicitly confirm the intended active master object state after validation.
6. Import/validate the exact serialized table on NPL through the existing offline repository boundary; all validation remains UI-free through ARC-1 after the structural import.

## Required gates

### Local

- red repository-contract replay before SAP change;
- `npm ci`, `npm test`, `git diff --check`;
- serializer diff limited to the expected enhancement-category field;
- complete diff, XML, compatibility, security, and Clean ABAP/Clean Core review.

### NPL / SAP_BASIS 750 first

- real `TABL ZTOAD` activation with no enhancement-category warning;
- active source shows `#NOT_EXTENSIBLE` and all seven fields are unchanged;
- zero inactive ZTOAD parts;
- `PROG ZTOAD` active syntax, all 67 ABAP Unit tests, and complete `DEFAULT` ATC compared with the 88-finding baseline.

### A4H / SAP_BASIS 758

- exact serialized table activation and active category/field verification;
- zero inactive ZTOAD parts;
- active report syntax, all 67 ABAP Unit tests, and recorded ATC variants compared with baseline;
- browser/ST22 is not applicable because runtime source, screens, transaction, and table columns are unchanged.

## Rollback

Restore `TABL ZTOAD` from the reviewed `master` serialization through native abapGit and explicitly activate it. No column conversion or persistent-data migration is involved. Restore the shared repository to `refs/heads/master` even if another gate fails.

## Plan review

- `#NOT_EXTENSIBLE` is the narrow SAP-supported category and does not promise unsupported appends.
- The repository contract checks the exact abapGit representation.
- Structural XML comes only from a native-abapGit round trip.
- The coordinated branch procedure prevents a system-only or master-only structural mutation.
- Live gates cover both supported releases while respecting NPL's no-UI boundary.
