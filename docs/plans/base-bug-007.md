# BASE-BUG-007 — restore complete native-abapGit installation

## Goal

Make the supported native-abapGit installation reproducibly complete: source, screens, GUI statuses, text elements, table, authorization object, and transaction are serialized, all A4H composite parts are active, and the first read-only query dispatch works without a new dump.

## Scope and constraints

- Treat the existing `STATUS010` failure as installation drift unless new evidence disproves it.
- Keep the shared native-abapGit link on `master` except for the coordinated, selective round trip; restore it to `master` after evidence is captured.
- Never hand-author abapGit serializer XML or claim source-only ARC-1 activation is a complete installation.
- Do not use NPL FLP, WebGUI, SAP GUI, or browser automation. Its exact structural gate is prerequisite-blocked by the absent transparent table/native-abapGit boundary.
- Use only the sanitized read-only query `SELECT SINGLE mandt FROM t000` for final dispatch.

## Reviewed implementation plan

1. **Research/root cause — complete.** Verify repository object closure, SAP GUI-status semantics, current abapGit program deserialization, and A4H inactive child state. Record the result in the linked research note.
2. **RED evidence — complete.** Add a local repository-closure/live-inventory contract and replay it against the original A4H state. Require it to name the inactive source, CUA, four screens, and text part.
3. **Plan review — complete.** Confirm the fix is structural state repair, not ABAP source logic; verify 7.50 limitations, Clean Core impact, security, rollback, and exact live gates.
4. **Permanent local guard — complete.** Run the complete local suite and ensure the installation contract accepts unrelated inactive objects but rejects all ZTOAD composite parts and ARC-1's JSON envelope.
5. **Native structural repair — complete.** Repository `000000000017` was refreshed on exact `master`; only `PROG ZTOAD` was pulled and its source, CUA, and four dynpros were activated. Unrelated package/table drift remained unselected.
6. **Live green gates — complete within available prerequisites.** Zero inactive ZTOAD parts, active syntax, 55/55 Unit, complete Cloud ATC baseline, prerequisite-aware S/4 readiness status, and active/source consistency are recorded. NPL remains blocked by the already documented missing-table prerequisite.
7. **Runtime acceptance — structurally unblocked but red overall.** A fresh A4H transaction renders `STATUS010` and reaches `EXECUTE`. The resulting post-dispatch Control Framework dump is independently registered as `BASE-RUN-006`; complete query smoke remains red and requires explicit maintainer acceptance before this plan can close without fixing that separate runtime finding.
8. **Final review and round trip — complete.** Native abapGit 1.133.0's separate screen-flow files were reviewed and exported selectively; the executable closure contract now protects that representation. Restore the shared repository to `master` after final evidence.
9. **PR/CI — in progress.** Push the structural candidate, open one Conventional Commit PR, wait for green CI, and audit the process. Move this plan to `docs/plans/finished/` only after the maintainer accepts the separate runtime limitation or `BASE-RUN-006` is fixed; rerun CI after any workflow change.

## Quality, compatibility, and security review

- No production ABAP logic changed, so no new language/API compatibility or Clean Core debt is introduced. The new screen files are native serializer output for existing dynpro flow logic.
- The Node contract uses only Node 18 built-ins and is part of the normal local/CI command.
- Live inventory evidence is read-only and may contain unrelated object/user/transport metadata; keep it temporary and commit only the normalized seven-part result.
- A full pull is potentially state-changing. Its rollback is the same coordinated native-abapGit pull of the previously reviewed `master` state, followed by complete activation and the same closure gates.
- A green source hash, syntax check, or ABAP Unit run cannot waive an inactive `PROG/PCA`, `PROG/PS`, or `PROG/PX` record.

## Evidence

- Initial A4H RED: live closure rejected `PROG/P`, `PROG/PCA`, four `PROG/PS` screens, and `PROG/PX` for ZTOAD.
- A4H structural GREEN: no inactive ZTOAD object or child part; GUI status and dynpros render; exact active server-normalized source SHA-256 `21ef81d0b925bca71182822a0e9650cb80b32c6e3fd3ae4d1d73576011cb74b7`.
- SAP gates: syntax 0 errors/2 known POSIX warnings; ABAP Unit 55/55; coverage 25.07% statements, 24.10% branches, 16.87% procedures; `ABAP_CLOUD_READINESS` 668 (462 P1/206 P2); S/4 readiness rows 0 but prerequisite-incomplete.
- Native round trip: commit `b1c2aa9` adds four screen-flow files and removes their duplicated XML representation. The unchanged report source SHA-256 is `87df3e26ef490e18ac22a3a761094f33b4ed8acb1ebd945d6023c6479bb8a29d`. Only `PROG ZTOAD` was pushed; unrelated DEVC/TABL drift remained unselected.
- Shared repository restoration: the A4H link was returned to `refs/heads/master` and the live inactive-child contract remained green. Its program drift is expected until this PR is merged; do not pull the old serializer representation over the active candidate.
- Runtime boundary: `STATUS010` is active and `EXECUTE` dispatches; a new 2026-08-07 04:31:22 UTC `SAPLOLEA`/`AC_SYSTEM_FLUSH` dump is separately tracked as `BASE-RUN-006`.
- NPL/7.50: exact ZTOAD install remains prerequisite-blocked because the real transparent table is absent and cannot be created through the available ADT endpoint.

## References

- [Research and root-cause report](../research/2026-08-06-base-bug-007-complete-installation.md)
- [Development playbook](../development.md)
- [Test strategy](../test-strategy.md)
