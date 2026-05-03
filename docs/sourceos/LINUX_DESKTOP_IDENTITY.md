# TurtleTerm Linux Desktop Identity

## Purpose

TurtleTerm should appear as TurtleTerm in Linux desktop environments and app catalogs.

## Current assets

Desktop entry:

```text
assets/sourceos/desktop/ai.sourceos.TurtleTerm.desktop
```

AppStream metadata:

```text
assets/sourceos/desktop/ai.sourceos.TurtleTerm.metainfo.xml
```

Application icon:

```text
assets/sourceos/brand/ai.sourceos.TurtleTerm.svg
```

## Installed paths

Homebrew on Linux installs:

```text
share/applications/ai.sourceos.TurtleTerm.desktop
share/metainfo/ai.sourceos.TurtleTerm.metainfo.xml
share/icons/hicolor/scalable/apps/ai.sourceos.TurtleTerm.svg
```

Release tarballs include the same files under the same prefix-relative paths.

## Product identity

Desktop environments should see:

```text
Name=TurtleTerm
StartupWMClass=TurtleTerm
Icon=ai.sourceos.TurtleTerm
Exec=turtleterm %u
```

## Remaining validation work

1. Add desktop-file validation in CI.
2. Add AppStream validation in CI.
3. Confirm app menu display on GNOME and KDE.
4. Confirm icon cache refresh behavior in native package lanes.
5. Confirm Wayland/X11 window class once deeper runtime app ID is patched.

## Acceptance criteria

Linux desktop identity is product-ready when GNOME/KDE menus, app switcher, launcher, icon, and app metadata present TurtleTerm without leaking private runtime names.
