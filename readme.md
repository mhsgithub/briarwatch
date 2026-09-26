# Briarwatch

Briarwatch is an original, single-player dark-medieval action RPG for Windows,
built in Godot 4.7.2. Diablo II informs its readable fixed-angle combat,
equipment and loot, deliberate wilderness encounters, and the rhythm of leaving
a safe settlement and returning with a story to tell. Its characters, places,
art and music selection belong to Briarwatch's own frontier setting.

The playable game has two outdoor maps, the Briar March and Hollowmere Marshes,
and six connected quests. The Old Watchtower, Warwick cellars, Dark Woods,
Sunken Chapel crypts and two floors of Darkmere Hold are separate regions.
The Centurion is the playable class, with levels 1–20, two talent trees,
equipment, trading, consumables, persistent exploration and local saves.
[Game description](docs/GAME.md) covers the world and quest flow;
[architecture](docs/ARCHITECTURE.md) covers the implementation.

## Play or edit

Use the **standard Godot 4.7.2 stable** editor with Compatibility rendering.
Import `project.godot` and press **F5** for the complete game. F6 runs only
an individual scene. No .NET SDK, online account or runtime asset download is
required.

On Windows, PowerShell helpers can fetch the pinned engine and launch the game:

```powershell
.\tools\setup.ps1
.\tools\launch.ps1
.\tools\launch.ps1 -Mode editor
```

`play.cmd` and `editor.cmd` are equivalent double-click launchers after setup.
`tools/setup.ps1` checks the official engine download against its pinned SHA-256;
the downloaded engine stays in ignored `.tools/`. An existing installation can
be passed to the launcher with `-GodotPath`.

| Input | Action |
|---|---|
| Left click ground or enemy | Move, or approach and repeat basic attacks |
| Left click NPC or drop; E nearby | Interact or collect |
| WASD | Move relative to the camera and cancel click orders |
| Shift + left click | Attack toward the cursor without approaching |
| Right click | Move or interact without selecting an enemy |
| 1–6 | Use the corresponding action slot |
| I / N / Q / M | Character and pack / talents / quest journal / region map |
| U | Testing shortcut: grant 15 talent points |
| Mouse wheel | Zoom |
| F5 | Save journey |
| Esc | Close a panel or open the pause menu |

The map reveals explored ground and shows only the active quest objective.
Investigation sites in quest five have no pins; the Dark Woods has no map.
Most panels pause combat. Gold appears in inventory and vendor screens.

## Journey

Warden Elric begins **The Crow's Captive** in Briarwatch. The Centurion takes
the Warwick Cellar Key from Darius Crowbane in the Old Watchtower, then rescues
Lord Kasparov from Jailor Brutus in **A Lord Beneath the Stones**. Kasparov
offers **Into the Lion's Den**, ending the Briar March chapter against Garrick
Vane and Bloodfang in the Dark Woods.

After that hand-in, Elric can take the player to Lanternwatch Camp in
Hollowmere Marshes. The camp provides trade, healing and talent resets.
**The Drowned Patrol** follows Sergeant Corvin Marr from Siltwater Landing to
Malrec Veyne's ritual beneath the Sunken Chapel. **The Unseen Hand** investigates
unmarked necromantic traces at Pilgrim Graves, the Drowned Tollhouse and the Old
Beacon in any order. **The Last Light of Darkmere** leads through an abandoned
keep to Malrec. Elric completes the Hollowmere chapter; the woman Malrec
summoned remains a mystery for later content. See [Hollowmere](docs/HOLLOWMERE.md)
and [balance](docs/BALANCE.md) for encounter, loot and reward details.

The Centurion has eleven equipment slots, a 20-cell pack and six assignable
action slots. Two-handed weapons reserve both hands. Strength adds melee damage;
each Crit Rating adds one percentage point of critical chance. Tonics heal over
five seconds and cannot stack. Chests release collectible floor loot. Enemies
telegraph major attacks through movement, light and sound. Death costs 10% of
carried gold, rounded up, and returns the character to the appropriate safe hub.
Unfinished boss fights reset for a retry; credited kills cannot pay out twice.
[Progression](docs/PROGRESSION.md) describes levels and talents.

## Saves

The local character is stored at Godot's `user://briarwatch_v1.json`,
normally `%APPDATA%/Godot/app_userdata/Briarwatch/` on Windows. The game
maintains a `.bak` copy. Loading resumes in Briarwatch or Lanternwatch at
full health. Inventory, gear, gold, quests, defeated spawn IDs, exploration,
opened chests, loose drops and action bindings persist. Living enemies regain
health on re-entry. The version-1 loader accepts older optional fields and
migrates retired item/quest state where supported.

Personal saves and build outputs are outside Git. To start a new character,
close the game and move both the primary save and its `.bak` to a backup
directory.

## Build and verify

```powershell
.\tools\launch.ps1 -Mode test
.\tools\launch.ps1 -Mode capture
.\tools\build.ps1
```

The test mode isolates personal saves. Capture mode writes rendered fixtures to
ignored `test-results/` for visual inspection. The build helper runs tests,
exports an embedded Windows x64 executable, smoke-tests it, and packages
`builds/Briarwatch-Windows-x64.zip`. Players extract the ZIP and run
`Briarwatch.exe`; they do not need Godot installed. Export templates, captures
and builds remain ignored. See [verification](docs/TESTING.md).

| Location | Purpose |
|---|---|
| `scenes/` | Composition roots and authored regions |
| `src/` | Combat, AI, quests, travel, persistence, presentation and UI |
| `content/` | Editable enemy, attack, item, loot, NPC, quest and talent data |
| `assets/` | Source textures, shaders, audio, music and license records |
| `tools/` | Pinned setup, authoring and build tools |
| `tests/` | Gameplay regressions and rendered captures |
| `docs/` | Game, architecture, balance, level-editing and asset guidance |

Read [level editing](docs/LEVEL_EDITING.md) before moving authored spawns or
changing saved IDs. Keep shared Resources immutable at runtime and preserve
region, encounter, spawn, item and quest IDs across releases. The art direction
is faceted timber and stone, cool greens and teals, amber firelight, layered
silhouettes and bronze-framed dark UI; see [visual direction](docs/VISUAL_DIRECTION.md)
and [asset provenance](docs/ASSETS.md). Source and license records for sound and
music are in [audio](docs/AUDIO.md).

The project currently has one playable class, a fixed-cell inventory and no
random affixes, crafting, multiplayer, streaming world or cloud service. These
are scope boundaries, not dependencies required to run the game.
