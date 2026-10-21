# Building Portable OBS 33 (from your fork)

Source: `mobiusbagel/obs-studio`, branch **`obs-33-portable`** — pinned to the official
33.0.0-rc2 tag (commit f1c0a116441b). Stock OBS, no source changes; the only
customization is portable mode, which is a config file, not a code change.

⚠️ 33.0.0-rc2 is a release candidate, not stable. Build it, test it, but keep
streaming on your current OBS install until you've kicked the tires. The portable
build is fully separate — it cannot touch your existing OBS config.

**Easiest path:** run `build-obs33-portable.bat` (in this same folder on your PC) —
it does steps 2–4 below automatically, checks prerequisites, and is safe to re-run.

## 1. Prerequisites (install once)

- **Visual Studio 2026** with the "Desktop development with C++" workload.
  ⚠️ OBS 33's `windows-x64` preset uses the "Visual Studio 18 2026" generator —
  VS 2022 will NOT work for this build, even though it works for OpenCE.
- **CMake 3.28 or newer** — https://cmake.org/download (or the one bundled with VS)
- **Git for Windows**
- ~10 GB free disk (source + auto-downloaded deps)

No manual Qt or dependency installs — the CMake preset downloads the official
prebuilt obs-deps (version 2026-08-26) and Qt automatically on first configure.

## 2. Clone your fork

```powershell
cd E:\Games   # or wherever you want it
git clone -b obs-33-portable --recursive https://github.com/mobiusbagel/obs-studio.git obs33
cd obs33
```

## 3. Configure + build

From a **Developer PowerShell for VS 2026** (or regular PowerShell if VS is in PATH):

```powershell
cmake --preset windows-x64
cmake --build --preset windows-x64
```

First configure downloads several GB of dependencies — that's normal, and it's a
one-time cost. First build is the long one; later rebuilds are incremental.

## 4. Make it portable

Build output lands in `build_x64\rundir\RelWithDebInfo\`.
The executable is at `bin\64bit\obs64.exe` inside it.

Create an empty file named **`portable_mode.txt`** in the `RelWithDebInfo` **root**
folder (next to `bin`, `data`, `core`) — NOT next to obs64.exe. Per the OBS 33
source (frontend/obs-main.cpp), Windows checks `../../portable_mode.txt` relative
to the exe in `bin\64bit`, i.e. the rundir root. From `build_x64\rundir\RelWithDebInfo`:

```powershell
New-Item portable_mode.txt
```

From then on, OBS stores **all** config, profiles, scenes, and plugins in a
`config` folder inside the build folder instead of `%APPDATA%`. The whole
`RelWithDebInfo` folder is your portable OBS — copy it anywhere, run it from a
USB drive, back it up as one unit.

## 5. First-run checks

1. Launch `obs64.exe` → Help → About should read **33.0.0-rc2**
2. Tools → **Plugin Manager** should open (the new 33 plugin system)
3. Add a browser source and confirm it loads (this exercises the new CEF 150 —
   the biggest under-the-hood change in 33; watch for weirdness here)
4. Confirm your `config` folder was created inside the portable folder
   (proof portable mode is active)

## Notes

- **Your plugins** (Exeldro Move, Move Transition, 3D Effect): not part of this
  stock build by your call. If you later copy them in, OBS 33 loads third-party
  plugins from the new location and flags old-style installs as **Legacy** in the
  plugin manager. They still work in 33; legacy loading is removed in 34.
- **Upstream updates:** when 33.0 goes stable, the `obs-33-portable` branch can be
  re-pointed at the stable tag the same way this one was created — just ask.
- The fork's `master` branch is untouched; this branch is your build line.
