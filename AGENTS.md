# Working on picoboot_host

Guidance for AI agents and contributors. Read this before changing code.

picoboot_host is a PICOBOOT host for the Raspberry Pi RP2350 (and RP2040) boot ROM in BOOTSEL mode: flash erase /
write / verify, reboot, chip id, in Rust on `nusb` (no `libusb`). It was extracted from
[wire_weaver](https://github.com/vhrdtech/wire_weaver) (CLT-21, where it still powers
`wire_weaver_client::follow::rp2_update()` and `ww bootsel`) and has no WireWeaver dependency of its own.

## FEATURES.md is the source of truth

[FEATURES.md](FEATURES.md) lists every feature with its status, every known bug, and what is planned, with stable
IDs per area.

- **Read the relevant area before starting.**
- **Name IDs with a short slug when talking to the user** (answers, plans, summaries, tables): e.g. `IMG-2
  uf2-family-filter`, never a bare `IMG-2`. The slug is 2-4 kebab-case words from the item's title. Commit messages,
  CHANGELOG entries and code `TODO`s keep the bare ID.
- **Update it in the same commit** as the code: mark items done with a pointer to the code, add bugs found but not
  fixed (next free ID of the area), move obsolete items to a *Dropped and superseded* section. Never renumber or
  reuse an ID.
- Don't track status anywhere else (README checklists, TODO files).

## CHANGELOG.md records every change

[CHANGELOG.md](CHANGELOG.md) is the history, FEATURES.md the current state; keep both. Every change a user of the
crate would notice gets an entry under `## Unreleased` in the same commit (`### ⚠️ Breaking`, `### 🚀 Features`,
`### 🐛 Fixes`), naming the public items involved. On a release, rename `## Unreleased` to the version and date and
start a new empty one; bump the version in `Cargo.toml` to match (SemVer, pre-1.0 so minor is the breaking position).

## Sans-IO core, `sim` for tests

[`PicobootIo`] (`src/io.rs`) is the only boundary `Picoboot` (`src/client.rs`) talks through: `usb::NusbIo`
(feature `usb`, real devices via `nusb`) and `sim::SimRp2350` (feature `sim`) are the two implementations. Any new
command or flow goes into `client.rs`/`proto.rs` against that trait, never against `nusb` directly, so it stays
testable without hardware. `sim::SimRp2350` models the boot ROM at the level of PICOBOOT's USB transfers (command
packet, data phase, zero-length status phase, stalls, `IF_RESET` / `IF_CMD_STATUS`) and flash as NOR flash behaves
(erase sets bits, write only clears them) — extend it when a new command needs device-side behaviour to test
against.

## Commands

```sh
cargo test              # or: cargo nextest run
cargo clippy --all-targets -- -D warnings
cargo fmt --check
just test               # same, via the justfile
just lint
```

Commit messages use Conventional Commits with a scope (`feat(image): ...`, `fix(usb): ...`): a short imperative
summary line, a blank line, then a body explaining what changed and why.

