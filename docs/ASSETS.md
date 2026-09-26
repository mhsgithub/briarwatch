# Asset provenance

Briarwatch's geometry, shaders, colors, text, names, layouts and vector item
icons were authored for this original setting. The faceted world meshes are
built through native Godot scenes and scripts; they are not imported franchise
models or copied maps. [VISUAL_DIRECTION.md](VISUAL_DIRECTION.md) defines the
style and preserves atlas prompts. Audio sources, synthesis and music licenses
are documented in [AUDIO.md](AUDIO.md) and the asset license files.

## Painted interface textures

These textures were generated specifically for Briarwatch and are committed
source inputs. The interface supplies dark enamel backings where needed. Atlas
regions are selected through item Resources, so additions can use a custom icon
without replacing existing cells.

| Source asset | Purpose |
|---|---|
| `assets/ui/equipment_atlas.png` | 4×4 original equipment and consumables |
| `assets/ui/field_gear_atlas.png` | 4×4 March equipment expansion |
| `assets/ui/panel_frame.png` | Engraved bronze nine-slice panel frame |
| `assets/ui/talent_atlas.png` | 4×4 Centurion talent and family-seal art |
| `assets/ui/marsh_gear_atlas.png` | 4×4 Hollowmere wildlife-drop equipment |
| `assets/ui/rowan_gear_atlas.png` | 3×2 Lanternwatch vendor equipment |

The original inventory art, character/pack layout and bronze/enamel palette
remain the visual baseline. The exact first equipment/talent cell mapping and
prompts are in [VISUAL_DIRECTION.md](VISUAL_DIRECTION.md) and
[TALENT_ART_PROMPT.md](TALENT_ART_PROMPT.md). The marsh gear prompt is retained
in `assets/ui/marsh_gear_prompt.txt`. The final PNGs, not a generation service,
are needed to run or build the game.

## World and character art

`Geometry`, `WorldProp`, `ActorVisual`, `Terrain`, `Road` and region-specific
components create timber, slate, stone, marsh vegetation, bridges, ruins,
fortifications and layered actor silhouettes. The Watchtower, Warwick cellar,
Dark Woods, chapel crypts and Darkmere Hold use editor-visible native geometry
with authored collision and spawn markers. Dark Woods thickets use a local
visibility shader; Hollowmere water and mist have dedicated shaders.

Garrick, Bloodfang, Brutus, Corvin, the undead and Malrec have original native
models and presentation. Fire, corruption and Malrec's dark boiling patch have
separate visual components and shaders. The vector item icons for Bloodclaw,
Captain's Breastplate, Soldier's Pauldrons, Black Reliquary
and Veyne's letter are authored in this repository. These are editable source
assets, not runtime downloads.

## Sound, music and fonts

Final effects are included under `assets/audio/`; their recorded CC0 sources
and project-authored synthesis recipes are documented in
`assets/audio/LICENSES.md` and [AUDIO.md](AUDIO.md). Complete music tracks and
their licenses are in `assets/music/` and `assets/music/LICENSES.md`. No
network access is needed for playback.

Body UI uses Godot's bundled fallback font. Headings request local Georgia,
Noto Serif and then serif, with Godot fallback; no system font is redistributed.
Heading metrics may therefore differ slightly between PCs. Godot is obtained
separately under its own license; see https://godotengine.org/license/.
No project-wide open-source license has been selected on the owner's behalf.
