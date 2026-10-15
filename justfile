# just cheatsheet https://cheatography.com/linux-china/cheat-sheets/justfile/

# List all available targets
default:
    @just --list

# Run the test suite
test:
    cargo nextest run --no-fail-fast

# Format and lint checks (what CI runs)
lint:
    cargo fmt --check
    cargo clippy --all-targets -- -D warnings

# picoboot_host is a library crate, no binary to install on this PC
install:
    cargo build --release

# Library crate, nothing runs on this PC: staying current is a plain pull
deploy:
    git pull --ff-only
