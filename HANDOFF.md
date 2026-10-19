# HANDOFF — bootsel-elf (s/19oct2026-bootsel-elf)

Context handoff at ~400k tokens. Picks up where this note leaves off; read it fully before doing anything.

## What the job is

Flash RP2040/RP2350 firmware ELFs straight through the boot ROM (PICOBOOT), no picotool/elf2uf2, across 4
worktrees all on branch `s/19oct2026-bootsel-elf`:

- `~/git/.wt/bootsel-elf/picoboot_host`
- `~/git/.wt/bootsel-elf/wire_weaver`
- `~/git/.wt/bootsel-elf/usb_io_fw`
- `~/git/.wt/bootsel-elf/embedded_bedrock`

Full original brief is in this session's very first user message (search the transcript for "Flash RP2040/RP2350
firmware ELFs straight through the boot ROM"); re-read it if anything below is unclear.

## Status: everything done and verified except one step in flight

### picoboot_host — LANDED AND ON GITHUB, confirmed done

- `Image::from_elf` (IMG-4): PT_LOAD segments by physical address, pure-Rust via `object` crate (feature `elf`).
- TEST-2 fixed: `just test`/`just lint` now pass `--all-features` (were silently skipping `sim`/`elf`-gated
  tests).
- **Gotcha that cost real time, now fixed**: CHANGELOG.md had `## Unreleased` (no brackets) from the extraction
  commit, but `tpm_cli`'s `land.rs` looks for the literal string `"## [Unreleased]"` (with brackets). Without
  brackets, `unreleased()` returns `None`, `bump_from_changelog` returns `Bump::None`, and `tpm land` bails with a
  confusing `"[Unreleased] is empty but ... has: feat(image): ... (IMG-4)"` even though the section visibly has
  content. Fixed by changing the heading to `## [Unreleased]` (matches wire_weaver's and usb_io_fw's own
  convention).
- **Landed**: `main` is at `795498d release: 0.1.0`, tagged `v0.1.0`, confirmed pushed to GitHub (`git ls-remote
  origin main` → `795498dd2b17d8ff2711b8db78cccad56607bd2d`). Nothing further needed here.

### wire_weaver — NEXT STEP, do this now (user's explicit instructions, 19 Oct 2026)

- `ww bootsel flash` detects an ELF by magic bytes (not extension) and flashes it via `Image::from_elf`; help
  text, `docs/cli_reference.md`, `docs/transport/follow_reboot.md`, `FEATURES.md` (CLT-21) all updated. Commit
  `43424f29`.
- `ww_picoboot` is currently a **path dependency** on `../picoboot_host` (root `Cargo.toml`,
  `[workspace.dependencies]`, with an explanatory comment), because picoboot_host's commits were unpushed when
  this was written.
- **The user said exactly this** (do it in this order):
  1. Point `ww_picoboot` back to the git dependency, **tag `"v0.1.0"` (or rev `795498d`)** — the user said either
     is fine, prefer the tag:
     ```toml
     # Its own repo since CLT-21; a registry version once picoboot_host is on crates.io.
     ww_picoboot = { package = "picoboot_host", git = "https://github.com/vhrdtech/picoboot_host", tag = "v0.1.0", default-features = false }
     ```
     Delete the "Path dep while ... is unpushed" comment lines above the current entry.
  2. Regenerate `Cargo.lock` at that commit (`cargo update -p picoboot_host` or a plain `cargo check`/`cargo
     build`) — verify it now has `source = "git+https://github.com/vhrdtech/picoboot_host?tag=v0.1.0#795498d..."`
     (or `?rev=795498d...`) and still pulls in `object`/`memchr` (the `elf` feature).
  3. **Rebase all three remaining repos onto their own `main`** (wire_weaver, usb_io_fw, embedded_bedrock) — the
     user asked for this explicitly, check each one's `main` has moved since this branch forked before rebasing
     (usb_io_fw was already rebased onto 0.10.2 earlier in this job; re-check it's still current, `main` may have
     moved again).
  4. **`just test` and `just lint` in each of the three repos** (wire_weaver, usb_io_fw, embedded_bedrock) —
     wire_weaver's own `just check`/`just test` build `mcu/` and every `examples_mcu/` board too and take a long
     time; at minimum re-run what was actually verified earlier for wire_weaver: `cargo nextest run -p
     wire_weaver_cli -p wire_weaver_client -p follow_reboot` and `cargo clippy -p wire_weaver_cli -p
     wire_weaver_client --all-targets --all-features -- -D warnings`, plus the full `just test`/`just lint` if
     time allows.
  5. Commit the `Cargo.toml` + `Cargo.lock` change on wire_weaver's branch (and anything the rebases touched, if
     the rebases weren't clean fast-forwards — check for conflicts, there shouldn't be any since nothing else
     changed those files in this job, but verify).
  6. **`tpm work say parent "rest ready"`** — the user's exact words.
  7. Also run `tpm work ready --note "..."` summarizing the whole thing once all four repos are confirmed clean,
     since that's this session's standing closing step.

### usb_io_fw — DONE, nothing further needed

- Rebased onto `main` (0.10.2, after `report-embassy-main` landed) cleanly, no conflicts.
- `just flash-bootsel [SERIAL]` recipe added (PLAT-5), commit `dd3dd90`.
- **Gotcha already fixed**: `b200_usb_io` is *not* a standalone one-crate workspace (unlike what the
  embedded_bedrock template generates) — it joins the repo-root Cargo workspace, so `cargo build --release` from
  inside `b200_usb_io/` puts the binary in the **workspace root's** `target/thumbv8m.main-none-eabihf/release/`,
  not a nested `b200_usb_io/target/...`. The justfile recipe already uses the correct path (`target/...`, not
  `b200_usb_io/target/...`) — this was caught and fixed during hardware verification, already committed.
- `just test` and `just lint` both pass.

### embedded_bedrock — DONE, nothing further needed

- Template now generates `justfile` with a `flash-bootsel` recipe for `t.family == "rp"` targets only (both the
  plain and `--wire-weaver` layouts — verified by generating an rp2040, an rp2350b `--wire-weaver`, and an STM32
  project, confirming the STM32 one gets no justfile). Commit `971cdda`.
- `references/frameworks.md`'s RP2040/RP235x "alternative runners" line now points at `ww bootsel flash` instead
  of picotool/elf2uf2-rs.
- `cargo fmt --all --check` clean (no Rust source was touched, only the Python generator + Jinja templates +
  Markdown).

### Hardware check — DONE

Flashed `usb_io_fw`'s release ELF through the real rePort (B200, RP2350) on `omarchy-m1` via PICOBOOT, over a
reverse-SSH scratch clone at `/tmp/bootsel-elf-hwcheck` (gpd-omarchy → omarchy-m1, read-only fetch, never pushed;
already cleaned up / removed). The device rebooted and came back on USB answering `b200_usb_io_api@0.5.1` over
WireWeaver, same as before flashing. No further hardware testing needed for this job.

**Important safety gotcha found during this check**: the *globally installed* `ww` binary on both gpd-omarchy and
omarchy-m1 (`~/.local/bin/ww`, built from wire_weaver commit `f01b2daf`, predates this branch) has **no ELF magic
detection**. If pointed at an ELF file it silently treats the whole unstripped file as a raw binary and writes all
~3 MB of it (including DWARF debug info) starting at flash address `0x10000000` — this is not a crash, it just
silently does the wrong, dangerous thing. Do not use the globally installed `ww` for anything ELF-related until
wire_weaver lands on main and `ww` gets reinstalled from it; use a freshly-built one from this branch instead if
testing again before that.

## Other things filed along the way

- `P2618#19oct-1237` (tpm, skill tree gap): `ww bootsel flash` isn't in `skilltree.toml` yet.
- `IMG-5` (idea, picoboot_host FEATURES.md): RAM-load images aren't supported by `Image::from_elf` — it errors
  clearly instead.

## Rules that still apply

Same as this session's original brief: work only in these 4 worktrees, commit on `s/19oct2026-bootsel-elf` as you
go, never push, never run `tpm land` yourself (the user runs it — a `--dry-run` is fine and was used to debug the
CHANGELOG issue above), `tpm work ready --note "..."` when a step is actually ready, `tpm work say parent` for
questions/blockers, park (`tpm work park --reason "..." --for ...`) rather than ending a turn silently when
waiting on something external (hardware, a push, a person).

Delete this file (`git rm HANDOFF.md`) once the job is actually all the way done and `tpm work ready` is called
for the last time — don't leave it lying around after that point.
