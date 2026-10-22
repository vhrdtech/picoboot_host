# just cheatsheet https://cheatography.com/linux-china/cheat-sheets/justfile/

# List all available targets
default:
    @just --list

# Run the test suite, all features so sim- and elf-gated tests run too
test:
    cargo nextest run --no-fail-fast --all-features

# Format and lint checks (what CI runs)
lint:
    cargo fmt --check
    cargo clippy --all-targets --all-features -- -D warnings

# picoboot_host is a library crate, no binary to install on this PC
install:
    cargo build --release

# Library crate, nothing runs on this PC: pull current main and check it still builds
deploy:
    test -z "$(git status --porcelain)" || (echo "local changes present, refusing to deploy" >&2 && exit 1)
    git pull --ff-only
    just install
