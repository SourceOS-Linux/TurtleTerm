# TurtleTerm winget (Windows Package Manager) Manifest

## Install

```powershell
winget install SourceOS.TurtleTerm
```

Or with explicit source:
```powershell
winget install --id SourceOS.TurtleTerm --exact
```

## Submit to winget Community Repository

1. Fork https://github.com/microsoft/winget-pkgs
2. Copy manifest files to `manifests/s/SourceOS/TurtleTerm/1.4.0/`
3. Run validation: `winget validate --manifest manifests/s/SourceOS/TurtleTerm/1.4.0/`
4. Open a PR against microsoft/winget-pkgs

## Automated Submission via wingetcreate

```powershell
winget install Microsoft.WingetCreate
wingetcreate update SourceOS.TurtleTerm --version 1.4.0 --urls https://github.com/SourceOS-Linux/TurtleTerm/releases/download/v1.4.0/TurtleTerm-1.4.0-windows-x64.zip --submit
```
