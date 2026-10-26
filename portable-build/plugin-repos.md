# OBS Plugin GitHub Repos — Kris's 16

The plugin set from his main OBS (per the OBS 33 Plugin Manager "Missing" list,
2026-10-20), matched to each project's official GitHub repo (verified
2026-10-21 via the GitHub API).

## Exeldro (6)
| Plugin | Repo |
|---|---|
| 3D Effect | https://github.com/exeldro/obs-3d-effect |
| Freeze Filter | https://github.com/exeldro/obs-freeze-filter |
| Gradient Source | https://github.com/exeldro/obs-gradient-source |
| Move Transition | https://github.com/exeldro/obs-move-transition |
| Scene Notes Dock | https://github.com/exeldro/obs-scene-notes-dock |
| Source Clone | https://github.com/exeldro/obs-source-clone |

## FiniteSingularity (6)
| Plugin | Repo |
|---|---|
| obs-advanced-masks | https://github.com/FiniteSingularity/obs-advanced-masks |
| obs-composite-blur | https://github.com/FiniteSingularity/obs-composite-blur |
| obs-noise | https://github.com/FiniteSingularity/obs-noise |
| obs-retro-effects | https://github.com/FiniteSingularity/obs-retro-effects |
| obs-stroke-glow-shadow | https://github.com/FiniteSingularity/obs-stroke-glow-shadow |
| svg-source | https://github.com/FiniteSingularity/svg-source |

## Everyone else (4)
| Plugin | Repo |
|---|---|
| Aitum Stream Suite | https://github.com/Aitum/obs-aitum-stream-suite |
| autostarter | https://github.com/DaviBe92/Autostarter |
| StreamUP | https://github.com/StreamUPTips/obs-streamup |

## Excluded (Kris's call, 2026-10-21)
| Plugin | Repo | Why |
|---|---|---|
| obs-streamelements-core | https://github.com/StreamElements/obs-streamelements-core | SE.Live left out of the portable build — its transform pipeline conflicts with Move Transition. StreamElements overlays still work as plain browser sources; only the SE.Live docks/editor integration are lost. Main OBS keeps SE.Live; this exclusion is portable-only. |

## Install notes for the portable OBS 33
- **Use `update-plugins.bat`** (same folder): one click pulls each plugin's
  latest GitHub release and installs it in the right layout. It tracks
  installed versions in `plugins-installed.json`, so re-runs only fetch
  what changed. Close OBS first — the script refuses to run while OBS is open.
- Destinations (verified in the OBS 33 source,
  `frontend/plugin-manager/PluginModuleLoader_Windows.cpp`):
  new layout → `RelWithDebInfo\plugins\<plugin>\<plugin>.dll` + `data\`;
  legacy layout → `RelWithDebInfo\obs-plugins\64bit\` +
  `RelWithDebInfo\data\obs-plugins\<plugin>\`. OBS 33 loads both in
  portable mode; legacy loading is removed in OBS 34.
- Four Exeldro plugins (3D Effect, Freeze Filter, Gradient Source,
  Scene Notes Dock) publish **no binaries on GitHub** — Exeldro distributes
  them via the OBS Forums. The updater copies those four from the main OBS
  install instead.
- 3D Effect (0.1.4, May 2025) has no OBS 32/33-targeted build, but it is
  **VERIFIED WORKING on OBS 33.0.0-rc3 (2026-10-26)**: Perspective mode
  rendered true foreshortening on a text source (Rot X 10° / Y 25° /
  FOV 90), no artifacts or crashes. Caveats: strong FOV/rotation renders
  outside the source's bounding box, and the known game-capture cursor
  white-box bug still applies — keep it off captures that need a visible
  cursor. OBS's built-in 3D Transform remains the fallback for simple tilts.
- FiniteSingularity's Oct 2026 releases (noise 1.1.0, stroke-glow-shadow
  1.6.1, composite-blur 1.6.1) switched their `-windows-x64.zip` to a
  wrapped-folder shape (`<plugin>\<plugin>.dll` + `data\` inside the zip).
  Composite Blur's change was silent — the updater reported success but
  nested the folder one level too deep, so OBS never saw it (caught in the
  2026-10-25 Plugin Manager audit). The updater now verifies each plugin's
  DLL actually lands at `plugins\<name>\<name>.dll` before calling it
  up to date, and re-installs when it didn't.
- **KNOWN INCOMPATIBLE (2026-10-25): Aitum Stream Suite 1.2.4 crashes OBS 33
  on startup** — its scenes-dock browser hits a CEF check failure
  (exception 80000003 in libcef.dll, called from aitum-stream-suite.dll
  during OnFirstLoad; two identical crash logs). 1.2.4 (Sep 22, 2026)
  predates OBS 33's CEF 127→150 jump. Install itself was verified complete
  (single DLL + locale data). Keep Aitum out of the portable build until
  Aitum ships an OBS 33 build; the updater will pull it automatically once
  a newer release exists (rename the quarantined folder back / let the
  updater recreate it).
