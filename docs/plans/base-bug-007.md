# BASE-BUG-007 — restore complete native-abapGit installation

## Goal

Make the supported native-abapGit installation reproducibly complete: source, screens, GUI statuses, text elements, table, authorization object, and transaction are serialized, all A4H composite parts are active, and the first read-only query dispatch works without a new dump.

## Scope and constraints

- Treat the existing `STATUS010` failure as installation drift unless new evidence disproves it.
- Keep the shared native-abapGit link on `master`; do not publish or switch it to an unmerged structural branch during the GitHub outage.
- Never hand-author abapGit serializer XML or claim source-only ARC-1 activation is a complete installation.
- Do not use NPL FLP, WebGUI, SAP GUI, or browser automation. Its exact structural gate is prerequisite-blocked by the absent transparent table/native-abapGit boundary.
- Use only the sanitized read-only query `SELECT SINGLE mandt FROM t000` for final dispatch.

## Reviewed implementation plan

1. **Research/root cause — complete.** Verify repository object closure, SAP GUI-status semantics, current abapGit program deserialization, and A4H inactive child state. Record the result in the linked research note.
2. **RED evidence — complete.** Add a local repository-closure/live-inventory contract and replay it against the original A4H state. Require it to name the inactive source, CUA, four screens, and text part.
3. **Plan review — complete.** Confirm the fix is structural state repair, not ABAP source logic; verify 7.50 limitations, Clean Core impact, security, rollback, and exact live gates.
4. **Permanent local guard — complete.** Run the complete local suite and ensure the installation contract accepts unrelated inactive objects but rejects all ZTOAD composite parts and ARC-1's JSON envelope.
5. **Native structural repair — pending GitHub/native-abapGit availability.** Refresh repository `000000000017` on exact `master`, inspect drift, pull/deserialise the complete object set, and activate every queued part. Do not stage unrelated changes.
6. **Live green gates — pending.** Require zero inactive ZTOAD program parts, clean native-abapGit status, active syntax, ABAP Unit, `ABAP_CLOUD_READINESS`, prerequisite-aware `S4HANA_READINESS_2023`, and active/serialized object consistency.
7. **Runtime acceptance — pending.** In a fresh A4H transaction, dispatch the read-only query, verify the result path, and compare ST22 before/after.
8. **Final review and round trip — pending.** Refresh native abapGit again, review any serializer delta, update the finding/research/evidence, and move this plan to `docs/plans/finished/` only when every available gate is green or explicitly maintainer-accepted.
9. **PR/CI — pending GitHub recovery.** Commit/push the completed candidate, open one Conventional Commit PR, wait for green CI, audit the process, and rerun CI after any workflow change.

## Quality, compatibility, and security review

- No production ABAP change is currently justified, so no new language/API compatibility or Clean Core debt is introduced.
- The Node contract uses only Node 18 built-ins and is part of the normal local/CI command.
- Live inventory evidence is read-only and may contain unrelated object/user/transport metadata; keep it temporary and commit only the normalized seven-part result.
- A full pull is potentially state-changing. Its rollback is the same coordinated native-abapGit pull of the previously reviewed `master` state, followed by complete activation and the same closure gates.
- A green source hash, syntax check, or ABAP Unit run cannot waive an inactive `PROG/PCA`, `PROG/PS`, or `PROG/PX` record.

## Evidence so far

- Local `npm test`: configured abaplint 0; repository contract green; four installation-contract tests green.
- `git diff --check`: green.
- Repository serialization: `LCL_OBJECT_PROG`, four required screens, three required statuses/titlebars, TABL, SUSO, and TRAN are present.
- A4H RED: live closure rejects `PROG/P`, `PROG/PCA`, four `PROG/PS` screens, and `PROG/PX` for ZTOAD.
- Production source has not changed and A4H was not structurally mutated during research.

## References

- [Research and root-cause report](../research/2026-08-06-base-bug-007-complete-installation.md)
- [Development playbook](../development.md)
- [Test strategy](../test-strategy.md)
