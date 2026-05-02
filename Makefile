.PHONY: all fmt build check test docs servedocs turtle-build turtle-smoke turtle-package turtle-homebrew-test turtle-release-check

all: build

test:
	cargo nextest run
	cargo nextest run -p wezterm-escape-parser # no_std by default

check:
	cargo check
	cargo check -p wezterm-escape-parser
	cargo check -p wezterm-cell
	cargo check -p wezterm-surface
	cargo check -p wezterm-ssh

build:
	cargo build $(BUILD_OPTS) -p wezterm
	cargo build $(BUILD_OPTS) -p wezterm-gui
	cargo build $(BUILD_OPTS) -p wezterm-mux-server
	cargo build $(BUILD_OPTS) -p strip-ansi-escapes

fmt:
	cargo +nightly fmt

docs:
	ci/build-docs.sh

servedocs:
	ci/build-docs.sh serve

# TurtleTerm distribution helpers. These are intentionally additive and do not
# alter upstream WezTerm build targets.
turtle-build:
	cargo build --release --locked -p wezterm
	cargo build --release --locked -p wezterm-gui
	cargo build --release --locked -p wezterm-mux-server

turtle-smoke:
	python3 assets/sourceos/tests/test_sourceos_term_smoke.py
	bash -n packaging/scripts/install-turtle-term.sh
	bash -n packaging/scripts/package-turtle-term.sh
	bash -n packaging/scripts/bootstrap-homebrew-tap.sh
	python3 -m py_compile packaging/scripts/render-stable-homebrew-formula.py assets/sourceos/bin/sourceos-term assets/sourceos/bin/turtle-term

turtle-package: turtle-build turtle-smoke
	bash packaging/scripts/package-turtle-term.sh "$${TURTLE_TERM_VERSION:-turtle-term-dev}" "$${TURTLE_TERM_TARGET:-$$(uname -s)-$$(uname -m)}"

turtle-homebrew-test:
	brew install --HEAD ./packaging/homebrew/Formula/turtle-term.rb
	brew test turtle-term

turtle-release-check: turtle-smoke
	git diff --quiet
	git diff --cached --quiet
	git rev-parse --verify HEAD
