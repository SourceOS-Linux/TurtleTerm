Name:           turtle-term
Version:        0.1.0
Release:        1%{?dist}
Summary:        TurtleTerm trusted terminal and agent workbench

License:        MIT
URL:            https://github.com/SourceOS-Linux/TurtleTerm
Source0:        https://github.com/SourceOS-Linux/TurtleTerm/archive/refs/tags/turtle-term-v%{version}.tar.gz
ExclusiveArch:  x86_64 aarch64

BuildRequires:  cargo
BuildRequires:  cmake
BuildRequires:  desktop-file-utils
BuildRequires:  fontconfig-devel
BuildRequires:  freetype-devel
BuildRequires:  gcc
BuildRequires:  libxkbcommon-devel
BuildRequires:  openssl-devel
BuildRequires:  pkgconf-pkg-config
BuildRequires:  rust
BuildRequires:  wayland-devel
BuildRequires:  zlib-devel

Requires:       fontconfig
Requires:       freetype
Requires:       libX11
Requires:       libxcb
Requires:       libxkbcommon
Requires:       openssl-libs
Requires:       zlib

%description
TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench
for trusted command execution, terminal receipts, agent delegation, and
reproducible operator workflows.

%prep
%autosetup -n TurtleTerm-turtle-term-v%{version}

%build
cargo build --release --locked -p wezterm
cargo build --release --locked -p wezterm-gui
cargo build --release --locked -p wezterm-mux-server

%install
TURTLE_TERM_STAGE_PREFIX=%{buildroot}%{_prefix} packaging/scripts/stage-linux-package.sh

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/ai.sourceos.TurtleTerm.desktop

%files
%license LICENSE.md THIRD_PARTY_NOTICES.md
%{_bindir}/turtleterm
%{_bindir}/turtleterm-mux-server
%{_bindir}/turtle-term
%{_bindir}/turtle-agentd
%{_bindir}/turtle-agentctl
%{_bindir}/turtle-tmux
%{_bindir}/turtle-cloudfog
%{_bindir}/turtle-superconscious
%{_bindir}/turtle-agent-machine
%{_bindir}/sourceos-term
%{_sysconfdir}/turtle-term/turtleterm.lua
%{_libexecdir}/turtle-term/
%{_datadir}/applications/ai.sourceos.TurtleTerm.desktop
%{_datadir}/metainfo/ai.sourceos.TurtleTerm.metainfo.xml
%{_datadir}/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg
%{_datadir}/turtle-term/

%changelog
* Tue May 05 2026 SourceOS Maintainers <maintainers@sourceos.local> - 0.1.0-1
- Initial TurtleTerm Linux package scaffold
