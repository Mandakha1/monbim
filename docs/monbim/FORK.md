# MonBIM fork notes (for maintainers)

MonBIM is [BIMCraft](https://github.com/IPedrax/BIMCraft) (IPedrax and the BIMCraft contributors, MIT OR Apache-2.0, no
separate brand licence) with its own name and year, a Mongolian interface language, MonHydro's news and account, and a
per-user Windows installer. Forked 2026-11-16 from upstream `main` at `a0c57b73` (BIMCraft 0.12.0, "Large projects…", PR #449);
remote `upstream`. It is the third such fork, after MonCad (CADCraft, `~/moncad`) and Mon3D (SolidCraft, `~/monsolid`), and
follows their layout.

## What changed, and where

| Area | Change | Files |
|---|---|---|
| Name and year | `brand::NAME` "MonBIM", `brand::YEAR` "2026", `brand::FULL_NAME` "MonBIM 2026", `brand::AUMID` "MonHydro.MonBIM", `UPSTREAM` and `SOURCE` links. Next year: change `YEAR` and `FULL_NAME` only. | `crates/ui-egui/src/brand.rs` |
| Executables | `monbim`, `monbim-cli` via `[[bin]]` and `default-run`; package names stay `bimcraft*` so upstream merges stay small. MinGW builds ask for an 8 MiB main-thread stack and get the icon through windres. | `apps/*/Cargo.toml`, `apps/bimcraft/build.rs`, `apps/bimcraft-cli/tests/dwg.rs` |
| Window | Title `… · MonBIM 2026` (the start page's title bar too), eframe app name `MonBIM`, app id `com.monhydro.monbim`, autosave folder `monbim-autosave` | `apps/bimcraft/src/main.rs`, `crates/ui-egui/src/lib.rs` |
| Start page and About | The name and year, a "Based on BIMCraft" link (upstream) beside "MonBIM source code" (`SOURCE`); File › Help › About MonBIM… and the start page's footer open About | `crates/ui-egui/src/start.rs`, `crates/ui-egui/src/about.rs` |
| Folders | `%APPDATA%\MonBIM`, `~/Library/Application Support/MonBIM`, `~/.config/monbim`: favorites, settings, recent files, `bridge.json`, `update.json`, plugins, the start log, news and account state. Never shared with an installed BIMCraft. `BIMCRAFT_FAVORITES` still overrides. | `crates/core/src/favorites.rs` |
| Interface words | Every English "BIMCraft" in `crates/ui-egui` and `apps/*` says MonBIM (the profile is "MonBIM"; its saved code stays `bimcraft`); `bimcraft-cli` in messages is `monbim-cli`. Translations of those messages were carried over (the msgids and msgstrs renamed in each catalog before `cargo i18n update`). | `crates/ui-egui/src/*.rs`, `translations/ui/*.po` |
| CLI and MCP | Usage, version line (`monbim-cli 0.12.0`), MCP `serverInfo` `monbim` / "MonBIM", instructions | `apps/bimcraft-cli/src/{main,mcp,window,revit}.rs` |
| Updates | Repository `Mandakha1/monbim`, user agent `MonBIM/<ver>`, `--version` line `monbim <ver>`. **Automatic checks off** (`bimcraft_update::AUTOMATIC_CHECKS = false`): the repository starts private, and GitHub answers 404 without a key; File › Check for Updates Now still asks and says it couldn't. The startup switch is hidden while off. | `crates/update/src/{lib,net,updater,testing,tests}.rs`, `crates/ui-egui/src/updates.rs` |
| Mongolian | `Lang::Mongolian`, code `mn`, label "Монгол", interface only (projects stay English: a drawing's stroke lettering has no Cyrillic); `from_code` takes mn, mn-MN, mongolian, монгол. Its catalog `translations/ui/mn.po` was created from the template with every msgstr empty: it is being translated elsewhere. IBM Plex Sans and Mono have Ө ө Ү ү, so no font was added (a test reads their character maps). | `crates/ui-egui/src/lang.rs`, `crates/ui-egui/src/style.rs` (test), `translations/ui/mn.po` |
| News and account | `crates/mon-news`, `crates/mon-account`: copies of MonCad's (shared by the three products), with one change: MonCad's egui is 0.37 and MonBIM's 0.36, which has no `Id::unique`, so the four window ids are `egui::Id::NULL.with("…")`, which both versions have (taking that form into MonCad's copy would make the three identical again). A `rustfmt.toml` beside each keeps MonBIM's `cargo fmt` off them. `news_tick` (product `monbim`) starts both once the desktop attaches its HTTP GET (`BimApp::http_get`, `bimcraft_update::net::mon_get`: HTTPS to `raw.githubusercontent.com/Mandakha1/…` and `monhydro.com` only). File › Help › News and courses… / Account… (Мэдээ, сургалт… / Бүртгэл… in Mongolian). `MON_NEWS=0`, `MON_ACCOUNT=0` turn them off. | `crates/ui-egui/src/about.rs`, `crates/ui-egui/src/lib.rs`, `crates/update/src/net.rs`, `apps/bimcraft/src/main.rs` |
| Windows installer | NSIS, per-user (`%LOCALAPPDATA%\Programs\MonBIM`), Mongolian/English, Start menu "MonBIM 2026" and "MonBIM 2026 (AI)" (`--control 7676`), `AI-connect.txt`, AUMID registered, uninstaller, `/S`, `/DESKTOP=1`; ships NOTICE and the fonts' OFL.txt | `packaging/monbim/` |
| CI | `.github/workflows/monbim.yml` (Linux tests; Windows build, MCP smoke test, launch, NSIS, portable zip, checksums, silent install and uninstall; draft release on `v*` tags). Upstream's workflows are parked in `packaging/upstream-ci/`. | `.github/workflows/monbim.yml`, `packaging/upstream-ci/` |
| Docs | This file; README.md is MonBIM's (Mongolian and English), upstream's is `docs/upstream/BIMCraft-README.md`; NOTICE starts with MonBIM's header | `README.md`, `NOTICE`, `docs/` |

Tests that read the repository were kept true: the root NOTICE now starts with MonBIM's header, so the Revit reader's test
looks for its notice in it rather than at its start (`crates/rvt/src/tests/mod.rs`); the shared `mon-*` crates have no
`CLAUDE.md`, so the agent-docs test leaves them out (`crates/core/tests/agent_docs.rs`); the font-licence test also reads
MonBIM's installer and build script (`crates/ui-egui/src/tests/fonts.rs`).

Unchanged on purpose, so files stay BIMCraft's: the `.bimc`, `.bimt`, `.bimb` and `.bimf` formats, `FORMAT` and
`Model::migrate`, IFC's application name and the `BIMCraft_*` property sets, the "BIMCraft Lettering" text font name, the
publisher's `BIMCraftPublisher` key, the control port's `"app": "bimcraft"` hello, the plugin ABI (`bimcraft.*` imports),
crate and package names, `BIMCRAFT_*` environment variables. The core's messages (read by agents) still say BIMCraft in a few
places. Not yet rebranded: the app icon and logo (BIMCraft's, MIT OR Apache-2.0), the macOS, Linux and MSI packaging
(`packaging/macos`, `packaging/linux`, `packaging/windows`) and the updater's in-place install, which expects BIMCraft's MSI
asset names: a MonBIM release is offered with a Download button that opens its page. `monbim.exe` carries the icon but,
as upstream's, no version resource (Explorer shows no file description).

## Turning automatic update checks on

When `Mandakha1/monbim` is public and has a published release: set `AUTOMATIC_CHECKS = true` in
`crates/update/src/lib.rs` (the File menu then offers "Check for updates at startup" again) and fix the test that pins it.

## Merging upstream

```bash
git fetch upstream && git merge upstream/main
# conflicts are usually in the files above; keep MonBIM's side for names, upstream's for logic
grep -rn 'BIMCraft' crates/ui-egui/src apps --include='*.rs' | grep -v '^\S*:\s*//'   # new interface words to rebrand
cargo i18n update && cargo i18n check     # mn.po gets the new English messages, untranslated
cargo test -p bimcraft-ui-egui -p bimcraft-update -p bimcraft -p bimcraft-cli
```

Upstream changes to its README land in `docs/upstream/BIMCraft-README.md` by hand.

## Building

```bash
cargo run --release -p bimcraft                      # the desktop app (binary: monbim)
cargo build --release -p bimcraft -p bimcraft-cli    # target/release/monbim, monbim-cli
packaging/monbim/build-windows.sh                    # macOS/Linux host → Windows x64 setup.exe (mingw-w64 + NSIS)
```
