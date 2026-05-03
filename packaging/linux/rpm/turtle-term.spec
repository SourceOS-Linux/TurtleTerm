Name:           turtle-term
Version:        0.1.0
Release:        1%{?dist}
Summary:        TurtleTerm trusted terminal and agent workbench

License:        MIT
URL:            https://github.com/SourceOS-Linux/TurtleTerm
Source0:        https://github.com/SourceOS-Linux/TurtleTerm/archive/refs/tags/%{version}.tar.gz
BuildArch:      x86_64
Maintainer: SourceOS Linux <maintainers@sourceos.local>
Requires:       libc6, libfontconfig1, libfreetype6, libssl3, libx11-6, libxcb1, libxkbcommon0, zlib1g

%description
TurtleTerm is the SourceOS policy-aware, agent-addressable terminal workbench
for trusted command execution, terminal receipts, agent delegation, and
reproducible operator workflows.

%prep
%autosetup

%build
%{_builddir}/%{name}-%{version}/packaging/scripts/stage-linux-package.sh

%install
mkdir -p %{buildroot}%{_prefix}/bin
mkdir -p %{buildroot}%{_prefix}/share/applications
mkdir -p %{buildroot}%{_prefix}/share/metainfo
mkdir -p %{buildroot}%{_prefix}/share/icons/hicolor/scalable/apps

cp -R %{_builddir}/%{name}-%{version}/dist/* %{buildroot}%{_prefix}/

%files
%{_prefix}/bin/turtleterm
%{_prefix}/bin/turtleterm-mux-server
%{_prefix}/share/applications/ai.sourceos.TurtleTerm.desktop
%{_prefix}/share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml
%{_prefix}/share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg
%{_prefix}/share/turtle-term/*

%changelog
* Fri May 05 2026 SourceOS Maintainers <maintainers@sourceos.local> - 0.1.0-1
- Initial package