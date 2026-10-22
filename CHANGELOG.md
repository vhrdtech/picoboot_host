# picoboot_host changelog

## [Unreleased]

## [0.1.1] - 2026-10-22

### 🔧 Chore

- `just deploy` now refuses to run with local changes present, and runs `just install` (the library build check)
  after pulling, instead of only pulling (install-recipes-sweep, ops#22oct-1632).

## [0.1.0] - 2026-10-19

### ⚠️ Breaking

- Extracted from [wire_weaver](https://github.com/vhrdtech/wire_weaver) into its own repo: the crate is renamed
  from `ww_picoboot` to `picoboot_host`. No code changes otherwise; WireWeaver depends on it as a path (and, once
  published, git/registry) dependency aliased back to `ww_picoboot` in its own `Cargo.toml`, so its own source
  didn't need to change.

### 🚀 Features

- First version (CLT-21): PICOBOOT host for the RP2350 / RP2040 boot ROM in BOOTSEL mode on nusb. `Picoboot` with
  `exclusive_access`, `exit_xip`, `flash_erase`, `write`, `read`, `reboot2`, `get_sys_info` / `chip_id`, and
  `flash()` (erase the touched sectors, write, verify, with `Progress`). `Image` from UF2 files (family filter,
  RP2350-E10 dummy block skipped) or raw binaries. `usb::list` / `usb::open` find a BOOTSEL device by its serial
  number (the chip id). `sim::SimRp2350` (feature `sim`): a simulated RP2350 boot ROM at the transfer level for tests.
- `Image::from_elf` (feature `elf`, IMG-4): flash an ELF firmware straight from its `PT_LOAD` segments, taken by
  physical address (LMA); segments with no file bytes (`.bss`) are skipped, a load segment outside the flash XIP
  window is a clear error. Pure-Rust parsing on `object` (no `-sys` crates).

### 📝 Docs

- Product names written WireWeaver and ShrinkWrap in prose (P2534).
