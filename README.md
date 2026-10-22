# picoboot_host

PICOBOOT host for the Raspberry Pi RP2350 (and RP2040) boot ROM in BOOTSEL mode, in Rust on
[nusb](https://docs.rs/nusb): read, erase and write flash, query the chip, reboot. What `picotool` does, as a
library, so a host can update a device it rebooted into BOOTSEL without a button press or a separate tool.

Extracted from [wire_weaver](https://github.com/vhrdtech/wire_weaver) (CLT-21), where it still powers
`wire_weaver_client::follow::rp2_update()` and `ww dfu rp`, but is otherwise independent: no WireWeaver
dependency, usable from any Rust project that talks to an RP2040 / RP2350 boot ROM.

```rust,no_run
use picoboot_host::{Image, Picoboot, usb};

# async fn example() -> Result<(), picoboot_host::Error> {
let image = Image::from_uf2(&std::fs::read("app.uf2").unwrap(), &[picoboot_host::image::family::RP2350_ARM_S])?;
let mut pb = usb::open(None).await?; // the only BOOTSEL device connected
pb.flash(&image, &mut |stage, done, total| {
    eprintln!("{stage:?}: {done}/{total}");
})
.await?;
pb.reboot2(picoboot_host::proto::Reboot2::Normal, picoboot_host::proto::REBOOT_DELAY)
    .await?;
# Ok(())
# }
```

## What it does

- [`Picoboot`] runs commands over any [`PicobootIo`]: [`usb::NusbIo`] on a real device, [`sim::SimRp2350`]
  (feature `sim`) in tests — a boot ROM simulated at the level of PICOBOOT's USB transfers (command packets, data
  phases, stalls, `IF_RESET` / `IF_CMD_STATUS`), so the whole flash/verify/reboot sequence can be tested without
  hardware.
- [`Image`] holds what to write, from a UF2 file (family filter, the RP2350-E10 dummy block skipped, adjacent
  blocks merged into segments), an ELF file (feature `elf`; `PT_LOAD` segments by physical/flash address, `.bss`
  skipped), or a raw binary at an address; [`Picoboot::flash`] erases exactly the touched sectors, writes page by
  page, reads back and verifies, with a `Progress` callback for a progress bar.
- [`usb::list`] / [`usb::find`] / [`usb::open`] / [`usb::open_by_serial`] find and open a BOOTSEL device by its USB
  serial number — the chip id, the same a firmware can put into its own serial number so a host finds the same unit
  again after it reboots into BOOTSEL and back.
- [`Picoboot::chip_id`] / [`Picoboot::get_sys_info`] (RP2350 `GET_INFO`), `exclusive_access`, `exit_xip`,
  `flash_erase`, `read`, `write`, `reboot2` (RP2350 `REBOOT2`, including `FlashUpdate { base }` — "boot the image
  just written", what `picotool load -x` sends) for lower-level use.
- A command the device refuses (bad alignment, not permitted, ...) comes back as `Error::Command { cmd, status }`
  with the device's own [`proto::Status`], not a bare USB transfer error.

## Cargo features

- `usb` (default): real devices through `nusb`, no `libusb`.
- `sim`: [`sim::SimRp2350`], a simulated boot ROM for tests; no `usb` or `tokio` needed.
- `elf`: `Image::from_elf`, on `object` (no `-sys` crate, pure Rust).

## Not (yet) covered

OTP read/write and RP2040 `EXEC`/`VECTORIZE_FLASH` aren't implemented (only RP2350 flash + reboot paths are
exercised today). See [FEATURES.md](FEATURES.md).

## License

MIT, see [LICENSE](LICENSE).
