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
- Prefer the **ZIP** packages from each repo's Releases over the Windows
  installers — installers target the system OBS / `C:\ProgramData` locations,
  while the portable build keeps plugins inside its own folder tree.
- Watch item: 3D Effect (0.1.4, May 2025) has no OBS 32/33-targeted build —
  test it early; OBS's built-in 3D Transform is the fallback for simple tilts.
- obs-streamelements-core is the SE.Live core — the Move Transition reference
  notes a known conflict between Move Transition and SE.Live's transform
  pipeline. Both are in this set; test scene transitions with both loaded.
