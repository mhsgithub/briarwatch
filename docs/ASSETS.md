# Asset provenance

Project-specific geometry, shaders, colors, text, names, layouts, the shield icon
were authored for this project. Audio now uses edited CC0 recordings; see
[AUDIO.md](AUDIO.md) for authors, source URLs, licensing and build recipes. The three painted UI
textures below were AI-generated specifically for Briarwatch using the built-in
image-generation tool on 17 September 2026. No franchise assets, copied maps,
commercial character models or third-party game-art packs are included.

| Source asset | Method and purpose |
|---|---|
| `assets/ui/equipment_atlas.png` | Built-in image generation; 1254x1254 RGBA, 4x4 painted equipment/consumable atlas |
| `assets/ui/field_gear_atlas.png` | Built-in image generation; 4x4 equipment expansion atlas, using our original atlas as style reference |
| `assets/ui/panel_frame.png` | Built-in image generation; 1536x1024 RGBA, engraved bronze nine-slice panel border |

All final PNGs are source inputs within the project, not external runtime
dependencies; include them when committing the overhaul. Alpha is preserved;
the UI supplies an opaque dark backing.
Atlas cell size derives from the actual image width rather than the requested
generation size. Prompts and cell mapping are preserved in
[VISUAL_DIRECTION.md](VISUAL_DIRECTION.md). No API key or paid service is required
to run or edit the game with these assets. The imagegen skill informed their
production use, readability constraints and portable save locations.

World geometry is built by `Geometry`, `WorldProp`, `ActorVisual`, `Terrain` and
`Road`. Recorded audio is routed through `GameAudio` and `AudioLibrary`; final
WAVs are included under `assets/audio/`. Body UI uses Godot's bundled
fallback font. Headings request the installed system fonts Georgia, Noto Serif,
then serif, with Godot fallback when unavailable; no system font files are copied
or redistributed. Exact heading metrics can therefore differ between PCs.
Godot is distributed separately under its own license; see
https://godotengine.org/license/ and the engine's About/License panel when making
a distributable build.

No project-wide open-source license has been chosen on the user's behalf.

The watchtower update adds original native geometry in `tower_interior.gd`,
the procedural `tower_stone.gdshader`, a hand-authored vector cellar-key icon,
and a native two-handed axe/commander silhouette. No external art was downloaded.
Outlaw's Mantle reuses the existing shoulder icon (atlas cell 9) and uses its
hide-colored shoulder/cape appearance on the character. Boss sound cues reuse
the existing CC0 library with runtime pitch/gain treatment; see AUDIO.md.

## Centurion talent atlas — September 2026

`assets/ui/talent_atlas.png`: built-in image generation, original 1254×1254 RGBA
4×4 atlas. The imagegen skill guided painted-icon consistency, readability,
inspection and copying the result into the portable repository. Row-major cells:
Block, Whirlwind, Impale, Bloodthirst; Retaliate, Rampage, Bladestorm, Momentum;
Leap, Unshackled, Iron Constitution, Elemental Resolve; Fleetfooted, Blood and
Breath, Kasparov Family Seal, spare star. No original inventory art was replaced.
The exact prompt is in TALENT_ART_PROMPT.md. Warwick/Brutus/Kasparov and their
animations use original native geometry and code.
