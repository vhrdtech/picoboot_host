# picoboot_host features and roadmap

This file is the single source of truth for what picoboot_host does, what is broken and what is planned, for
humans and AI agents alike. [CHANGELOG.md](CHANGELOG.md) records what changed and when; this file records the
current state.

Last full review: 15 Oct 2026 (extracted from [wire_weaver](https://github.com/vhrdtech/wire_weaver) `ww_picoboot`,
commit `731f83f`, CLT-21).

## How to use this file

- **Status** of each item:
  - ✅ done
  - 🚧 in progress or partially done (the note says what is missing)
  - 🐛 implemented, but with known bugs
  - 📋 planned
  - 💡 idea, not committed to
- **IDs** (`PROTO-1`, `IMG-2`) are stable: never renumber or reuse one. New items take the next free number of
  their area. Use the ID in commit messages, CHANGELOG entries and code `TODO`s (`// TODO(IMG-3): ...`).
- Items are grouped by area. Each area lists what works first, then open items by priority.
- When finishing work, update the item in the same commit: mark it done, add a pointer (module, test), move it up
  to the done items of its area. Don't delete done items.
- A bug found but not fixed gets an entry with the input that triggers it.

## Protocol (`PROTO`)

- ✅ **PROTO-1 Command framing** — `proto::Cmd` encode/decode, the 32-byte command packet, magic, token,
  `CmdStatus` (`IF_CMD_STATUS` reply), `Status` (device refusal reasons).
- ✅ **PROTO-2 Sans-IO core** — `Picoboot<I: PicobootIo>` (`client.rs`) talks only through `io::PicobootIo`
  (`bulk_out`/`bulk_in`/`reset_interface`/`cmd_status`); `usb::NusbIo` and `sim::SimRp2350` are the two
  implementations. A stall is turned into `Error::Command { cmd, status }` with the device's actual reason,
  automatically (the interface is reset first).
- ✅ **PROTO-3 Core commands** — `EXCLUSIVE_ACCESS`, `EXIT_XIP`, `FLASH_ERASE`, `WRITE`, `READ`, `REBOOT2`
  (RP2350: `Normal` / `FlashUpdate { base }` / `Bootsel`), `GET_INFO` SYS (`get_sys_info`, `chip_id`).
- 📋 **PROTO-4 RP2040 `REBOOT`** — only `REBOOT2` (RP2350) is implemented; the RP2040 uses the plain `REBOOT` with
  a program counter / stack pointer instead.
- 📋 **PROTO-5 OTP read/write** — RP2350 `OTP_READ` / `OTP_WRITE` aren't implemented.
- 📋 **PROTO-6 `EXEC` / `VECTORIZE_FLASH`** — RP2040-only commands, not implemented.

## Images (`IMG`)

- ✅ **IMG-1 UF2 parsing** (`image.rs`) — family filter, RP2350-E10 dummy block skipped, adjacent blocks merged
  into non-overlapping segments, overlap is an error.
- ✅ **IMG-2 Raw binary images** — `Image::from_bin(addr, data)`.
- ✅ **IMG-3 Sector computation** — `Image::sectors()`: the touched sectors, erased (`0xFF`) bytes outside the
  image filled in, for `Picoboot::flash`'s erase/write/verify loop.

## Flashing (`FLASH`)

- ✅ **FLASH-1 Orchestrated flash + verify** — `Picoboot::flash()`: `exclusive_access` + `exit_xip`, erase the
  touched sectors, write page by page (skipping already-erased pages), read back and verify, release exclusive
  access, with a `Progress` callback (`Stage::{Erase,Write,Verify}`, bytes done/total) for a progress bar.

## USB (`USB`)

- ✅ **USB-1 Device discovery** (`usb.rs`, feature `usb`) — `list`, `find` (by serial, exact match ignoring
  case), `open`, `open_by_serial`, claiming the vendor-class interface with two bulk endpoints, `IF_RESET` on
  connect.
- 📋 **USB-2 Linux kernel driver detach** — on Linux, a kernel driver claiming the interface isn't detached
  automatically (unlike some other PICOBOOT implementations); claiming fails instead. Low priority: BOOTSEL mode
  doesn't normally attract a kernel driver.

## Tests (`TEST`)

- ✅ **TEST-1 Simulated boot ROM** (`sim.rs`, feature `sim`) — `SimRp2350`: command/data/status phases, stalls on
  refused commands, NOR-flash write semantics (programming only clears bits), `fail_next` to inject a refusal.
  Covers flash+verify+reboot, chip id, refusal recovery, a write without erase failing verify.

## Dropped and superseded

(none yet)
