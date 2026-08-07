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

## Validation progress

- Red contract commit `fb60eca` failed at the exact missing `EXCLASS 1` assertion.
- Native-abapGit candidate commit `4206a1a`, table XML SHA-256 `0a7b98b6c073e5062c56bfd314dc297ecd88dc0ea685bee643caabc9a76a1f40`.
- Local `npm ci`, `npm test`, and `git diff --check` are green.
- A4H candidate activation/state, 67/67 Unit, syntax, inactive inventory, and recorded ATC gates are green; browser/ST22 remains not applicable.
- A4H is restored to full `refs/heads/master`; current master report and pre-change table are active with no inactive divergence. The known table drift remains visible until this PR merges.
- NPL imported `/tmp/ztoad-base-ddic-001.zip` (SHA-256 `a5c5745c55304e34f334ddb6b1e4ec7c4c3fbde9cf6ce46d01264f963059a4c5`). The maintainer accidentally selected all four repository objects instead of only `TABL ZTOAD`; this was safe because the archive's `PROG ZTOAD` was exact current `master` and `TRAN`/`SUSO` were unchanged. The later `DEVC` deletion proposal was not selected or applied.
- ARC-1 then explicitly activated `TABL ZTOAD` and `PROG ZTOAD`. The table reads as `#NOT_EXTENSIBLE` with the same seven fields, `PROG ZTOAD` syntax has zero errors, all 67 Unit tests pass, `DEFAULT` ATC remains 88 findings (3 P1, 4 P2, 81 P3, including the known time-zone prerequisite finding), and the global inactive inventory contains no ZTOAD part.
- NPL's direct active-table object-state endpoint intermittently returns 404 even though the transparent table is searchable, activated, and readable through ARC-1's automatic version resolution. The compensating evidence is the explicit activation result, active automatic read, inactive-version response stating that no inactive draft exists, exact category/field comparison, and zero ZTOAD entries in the global inactive inventory. This is an ARC-1 adapter finding, not a product gate failure.

## Post-green process audit

- GitHub Actions run `31164462265` checked the merge candidate, installed the pinned dependency set, and passed abaplint with zero issues plus the repository and installation contracts. The external abaplint check also passed.
- The implementation remains limited to the native serializer output and its exact contract; the canonical metadata removals were generated by native abapGit and reviewed field by field rather than accepted as an unexamined XML rewrite.
- Both supported-release gates were performed against the exact serialized candidate. The broader NPL import was compared with the archive before it was accepted, and the dangerous system-local package deletion proposal was not applied.
- The durable workflow improvement is now in `docs/development.md`: structural-only offline pulls select only their intended object, `DEVC $ZTOAD2` deletion remains unselected, and an accidental broad selection requires an exact archive comparison before any further pull.
- The inconsistent NPL table object-state endpoint is recorded separately as `BASE-TOOL-005` and in the ARC-1 integration audit. It is compensated by independent evidence rather than misreported as a passing object-state call.
- No CI workflow change is needed: the existing quality job exercised the new repository contract on the merge commit and produced complete, readable output.
