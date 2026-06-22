# TurtleTerm Flatpak

## Build

```bash
flatpak-builder --force-clean build-dir ai.sourceos.TurtleTerm.json
```

## Install locally

```bash
flatpak-builder --install --force-clean build-dir ai.sourceos.TurtleTerm.json
```

## Run

```bash
flatpak run ai.sourceos.TurtleTerm
```

## Shell integration within Flatpak

The shell init scripts are bundled at `/app/share/turtleterm/shell/`. To use them from the host:

```bash
# Get the path
flatpak run --command=sh ai.sourceos.TurtleTerm -c 'ls /app/share/turtleterm/shell/'
```

## Flathub submission

See https://docs.flathub.org/docs/for-app-authors/submission for the submission process.
The `flathub.json` file restricts builds to x86_64 and aarch64.
