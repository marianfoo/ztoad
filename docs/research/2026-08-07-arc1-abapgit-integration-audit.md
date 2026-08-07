# ARC-1 native-abapGit integration audit on A4H

_Observed 2026-08-06 to 2026-08-07 with ARC-1 1.0.2, A4H SAP_BASIS 758 SP02, native abapGit 1.133.0, and repository key `000000000017`. No ARC-1 repository code is changed by this ZTOAD issue._

## What works

- A4H has the native abapGit ADT bridge installed and usable. Repository discovery, details, status/check, full-ref branch switching, selective staging, and selective push all worked through the bridge.
- Selective staging of `PROG ZTOAD` included only the five intended program serializer files and excluded unrelated `TABL`/`DEVC` drift.
- Native abapGit remained the authoritative complete-object round trip, while ARC-1 was effective for source reads/writes, activation, syntax, Unit, ATC, object state, and inactive-child diagnostics.
- The system is not missing a bridge component. The earlier clone namespace error belongs to the older ARC-1 request shape and should be retested with the current client before retaining it as an active system defect.

## ARC-1 gaps and recommended improvements

1. **CLI feature discovery is process-local.** A standalone `arc1 call SAPGit` can report no abapGit/gCTS even when the same system probe proves availability. The CLI dispatch creates a new client without reliably warming the feature cache. Probe on demand in direct CLI mode, or let an explicitly forced backend bypass a cold cache with a clear diagnostic.
2. **Read/write classification is too broad.** `SAPGit(action="stage")` currently performs a GET/status-style calculation but is rejected unless write scope is enabled. Classify the operation by actual backend side effect, or rename/document it if the endpoint mutates server state.
3. **Short branch names are accepted without a postcondition.** Switching to `master` returned `ok:true` while the repository remained on the feature branch; `refs/heads/master` worked. Normalize short refs to full refs and always reread/compare the selected branch before returning success.
4. **Remote authentication errors need an actionable contract.** Push without explicit remote credentials returned a generic HTTP 500/Unauthorized even though native WebUI credentials existed. Explain that WebUI user settings are not bridge credentials, identify the missing credential source without logging secrets, and distinguish remote Git authentication from SAP authorization.
5. **Success responses need verification.** Branch switching and push should report the observed repository/remote state after the operation, not only that the bridge request returned 2xx.
6. **Local report-class surgery is missing.** ARC-1 documentation describes qualified local-class method editing, but `SAPWrite(action="edit_method", type="PROG", method="lcl_editor~set_focus")` rejects the operation as CLAS-only. Support local classes in reports/includes or narrow the advertised contract. `edit_unit` is useful for FORM blocks but cannot replace a local method safely.
7. **Pre-write ABAP release propagation remains wrong.** The A4H pre-write linter selected v702 and rejected valid 7.50+ syntax although live preflight/syntax accepted it. Carry the probed/configured release into every write path, including `edit_unit`.
8. **Large-source ergonomics should be first class.** Complete report writes require callers to build a temporary JSON payload to avoid stdin `EAGAIN`. Add a `sourceFile`/`--source-file` option that reads locally inside the CLI, reports the source hash, and never logs full source or credentials.
9. **Evidence-friendly output is incomplete.** Return staged object/file inventories, selected full ref, before/after commit IDs, and the exact remote result in stable JSON. This would make selective native-abapGit procedures auditable without scraping log previews.
10. **Published MCP schemas can lag the installed CLI.** The connected SAPGit MCP contract exposed only read actions while the local ARC-1 1.0.2 CLI supported `stage`, `push`, and `switch_branch`; the same skew hid newer diagnostic actions. Publish the running server/client version in discovery, keep action enums generated from one source, and fail with an explicit upgrade/reload instruction instead of forcing callers to discover CLI-only capabilities experimentally.

## Safe workflow until those gaps are fixed

1. Probe the system and repository in the same ARC-1 process when possible.
2. Use full branch refs such as `refs/heads/master` and reread repository details after every switch.
3. Enable write scope only for genuine mutations and provide remote credentials through the approved secret channel; never print them.
4. Stage explicit object selections, review returned filenames, and never use **Add All** with unrelated drift.
5. Treat native abapGit as the complete serializer and ARC-1 source writes as source-only unless the exact child-object closure is independently proven.
6. After activation, require active/inactive main equality plus the global inactive-child inventory for `PROG/P`, `PROG/PCA`, `PROG/PS`, and `PROG/PX`.

## System-side conclusion

A4H already has the necessary native abapGit program and ADT bridge. The missing capabilities are mainly client orchestration, validation, credential diagnostics, and report-local edit ergonomics. No new A4H component should be installed on the evidence collected here.
