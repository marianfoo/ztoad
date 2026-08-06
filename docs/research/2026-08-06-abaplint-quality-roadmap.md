# Reproducing and reducing the full abaplint list

_Research date: 2026-08-06 · abaplint: 2.120.18 pinned_

## Hosted versus local results

The hosted [marianfoo/ztoad statistics](https://abaplint.app/stats/marianfoo/ztoad) are a useful historical signal, but the summary and detailed snapshot are not the current pull-request source. The hosted table reported 2,138 findings while its detailed older-source rule page contained 1,693. Neither used the repository's current focused configuration.

Running the pinned CLI against its complete default rule set on the current candidate source produces **1,857 findings across 57 rules**. This inventory deliberately uses abaplint's default `Newest` language profile so every default quality rule can run; it does not replace the repository's ABAP 7.50 compatibility configuration or change the supported release floor. The largest groups are:

| Rule | Count |
|---|---:|
| `space_before_colon` | 505 |
| `no_prefixes` | 329 |
| `prefer_pragmas` | 124 |
| `local_variable_names` | 122 |
| `preferred_compare_operator` | 109 |
| `check_text_elements` | 89 |
| `functional_writing` | 81 |
| `prefer_inline` | 66 |
| `check_subrc` | 50 |
| `sql_escape_host_variables` | 39 |
| `reduce_procedural_code` | 37 |
| `fully_type_itabs` | 31 |
| `prefer_is_not` | 28 |
| `strict_sql` | 18 |
| `obsolete_statement` | 14 |

The other 38 rule groups total 116 findings. The complete live list is reproducible with:

```sh
npm run lint:quality
```

The command asks the pinned abaplint executable for its own default configuration, runs that configuration from the repository root, prints the per-rule summary, and removes the temporary configuration. It intentionally exits successfully when findings exist. Use `npm run lint:quality -- --strict` only when validating that the total has reached zero.

## Why the required CI remains narrow

The checked-in `abaplint.json` is a zero-finding parser, type, test-consistency, and abapGit-XML gate. Replacing it with 1,857 required findings would make every pull request red and hide regressions in old noise. The full list is a burn-down backlog until it reaches zero; it is not a reason to weaken or suppress individual rules.

## Reduction order

1. **Correctness and security:** parser errors, dangerous statements, unchecked `sy-subrc`, SQL host escaping/strict SQL, database operations in loops, and unsafe dynamic behavior.
2. **Testable architecture:** extract parser/generator/auth/editor seams, reduce procedural code, type tables/constants, and remove external `FORM` calls.
3. **Obsolete and ambiguous code:** obsolete statements, macros, chained assignments, ambiguous statements, and comments that hide code.
4. **Mechanical style:** prefixes, spaces, names, operator preferences, inline declarations, and line formatting. Apply these in focused batches after behavior is characterized to keep reviews meaningful.

Each batch needs local lint, affected ABAP Unit tests, both supported live SAP gates, and no new browser/ST22 regression. When the full command is zero, make its strict form a required GitHub Actions step for every pull request.
