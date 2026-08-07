# Changelog

All notable changes to ZTOAD are documented here. Future entries are maintained by Release Please from Conventional Commit messages.

## [5.0.1](https://github.com/marianfoo/ztoad/compare/5.0.0...5.0.1) (2026-08-07)


### Bug Fixes

* bound temporary subroutine pools ([#32](https://github.com/marianfoo/ztoad/issues/32)) ([ef54657](https://github.com/marianfoo/ztoad/commit/ef546576280316c40641aa40e0f848b5affab72c))
* classify ZTOAD table as not extensible ([#26](https://github.com/marianfoo/ztoad/issues/26)) ([e5ae759](https://github.com/marianfoo/ztoad/commit/e5ae759aa0ea8d6a2f5efb7a53fd0956ec5b3286))
* enforce bounded SELECT results ([#33](https://github.com/marianfoo/ztoad/issues/33)) ([b6acc14](https://github.com/marianfoo/ztoad/commit/b6acc143e09590a48e3fef5b9ac3fda85834de0e))
* execute queries safely in WebGUI ([#24](https://github.com/marianfoo/ztoad/issues/24)) ([5218476](https://github.com/marianfoo/ztoad/commit/5218476739c16476f773e61759b4649fcc4c92ea))
* execute UNION as one SQL set ([a5ad27c](https://github.com/marianfoo/ztoad/commit/a5ad27cc73a50101441bc2a0c0767108bc25a2fc))
* generate aggregate CASE result types ([#21](https://github.com/marianfoo/ztoad/issues/21)) ([d532b2e](https://github.com/marianfoo/ztoad/commit/d532b2ec8d7a25fabed457bb2f660504636d424f))
* isolate generated query failures ([#31](https://github.com/marianfoo/ztoad/issues/31)) ([b0b4d9f](https://github.com/marianfoo/ztoad/commit/b0b4d9facb1d52d0f87dc0280f23fafc44d93391))
* parse top-level SQL clauses ([#28](https://github.com/marianfoo/ztoad/issues/28)) ([c5ca65b](https://github.com/marianfoo/ztoad/commit/c5ca65be7c8eabc692fa1beb68e334093f09a9b5))
* support ABAP SQL string functions ([#27](https://github.com/marianfoo/ztoad/issues/27)) ([0f056e8](https://github.com/marianfoo/ztoad/commit/0f056e8d5aa9d08d67cf3fd55511014249702421))
* verify complete native-abapGit installation ([#22](https://github.com/marianfoo/ztoad/issues/22)) ([2360fe4](https://github.com/marianfoo/ztoad/commit/2360fe4caee2672242abebc17b804bcb0c6aef6a))

## [5.0.0](https://github.com/marianfoo/ztoad/compare/4.0.4...5.0.0) (2026-08-06)


### ⚠ BREAKING CHANGES

* The NATIVE command and its arbitrary Native SQL execution path are no longer supported.

### Features

* establish tested development baseline ([50d590b](https://github.com/marianfoo/ztoad/commit/50d590bce0276128ce46fed6a9bb8cf0da25c607))


### Bug Fixes

* add ZTOAD transaction launcher ([8fb3131](https://github.com/marianfoo/ztoad/commit/8fb31315f444303bc774871de212a5d5681a5a4b))
* add ZTOAD transaction launcher ([#17](https://github.com/marianfoo/ztoad/issues/17)) ([a907835](https://github.com/marianfoo/ztoad/commit/a907835ce5278aed8cacd1e0f2432e0cccbd0e69))
* authorize every SELECT source ([#19](https://github.com/marianfoo/ztoad/issues/19)) ([1bf2d4d](https://github.com/marianfoo/ztoad/commit/1bf2d4d297455bd8004197a8a952b4d87877a4dc))
* generate strict select clauses in valid order ([5ca4cc9](https://github.com/marianfoo/ztoad/commit/5ca4cc9a3b81dd10e925b1bbe18691fdcd636adc))
* guard generated ABAP fragments ([#20](https://github.com/marianfoo/ztoad/issues/20)) ([27bb674](https://github.com/marianfoo/ztoad/commit/27bb67442279549369895cf2ba3ef609ddc3b517))
* retire arbitrary Native SQL execution ([#18](https://github.com/marianfoo/ztoad/issues/18)) ([dc065dd](https://github.com/marianfoo/ztoad/commit/dc065ddd5804a4dfe30d5a882ce4f78eb46975c1))
* support WebGUI query editor ([ca17984](https://github.com/marianfoo/ztoad/commit/ca179849328b78734350f55a181cf2b7da09431f))
* support WebGUI query editor ([b711f8b](https://github.com/marianfoo/ztoad/commit/b711f8be5dd8b82bc202223af00b6cf7598770d4))

## 4.0.4 (2022-06-15)

- Added authorization object `ZTOAD_AUTH`.

## 4.0.3 (2022-02-25)

- Increased the maximum number of saved queries to 1,000.
- Changed the master language to English.

Earlier history remains available in [README.md](README.md#changelog).
