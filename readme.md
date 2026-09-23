# Briarwatch

An original single-player PC action RPG set in a weathered frontier of timber
villages, old stone defenses, dangerous woodland roads and mist-covered marshes.
The playable foundation contains **the 256 × 224 metre Briar March and the
288 × 256 metre Hollowmere Marshes**, plus watchtower, Warwick cellar and Dark
Woods instances, four bosses, three linked quests, levels 1–20 and fourteen
Centurion talents, alongside loot, gear, trading and paid talent resets.

Read [the game description](docs/GAME.md) for creative direction and scope, and
[the architecture](docs/ARCHITECTURE.md) before extending systems.

## Run on Windows

**Engine: Godot 4.7.2 stable, standard edition.** Typed GDScript and Compatibility
rendering; no .NET SDK, package manager, external asset download or online account
is needed to play. Godot is the only runtime dependency.

1. Install/download [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import this repository's `project.godot` into Godot.
3. Press **F6** only for an individual scene; press **F5** to play the complete game.

Alternatively, from PowerShell in the repository:

```powershell
.\tools\setup.ps1              # Official Windows x64 engine, pinned SHA-256
.\tools\launch.ps1             # Play
.\tools\launch.ps1 -Mode editor
```

After setup, `play.cmd` and `editor.cmd` are convenient double-click launchers.
They set PowerShell's execution policy for that process only, not for the machine.
The engine download is stored in ignored `.tools/`; it is never required in Git.
An already installed engine can be passed as `-GodotPath` to the launch script.
For Windows ARM64, use the matching official engine directly in the editor; the
optional bootstrap script downloads x64 only.

## Build for Windows

Double-click `build.cmd`, or run the following from PowerShell:

```powershell
.\tools\build.ps1
```

The first build downloads the official Godot 4.7.2 export templates, verifies
their pinned SHA-256 checksum, runs the complete test suite, exports an embedded
Windows x64 executable and smoke-tests that exported game. The distributable
package is written to `builds/Briarwatch-Windows-x64.zip`. A player only needs to
extract that ZIP and run `Briarwatch.exe`; Godot and the project sources are not
required. Build outputs and downloaded templates remain ignored by Git.

## Play

| Input | Action |
|---|---|
| Left click ground | Walk there |
| Left click enemy | Approach and repeat basic sword attacks |
| Left click NPC / drop | Approach and interact / collect |
| WASD | Move relative to the camera; cancels click orders |
| Shift + left click/hold | Attack toward the cursor without approaching |
| Right click | Move / interact without targeting enemies |
| E | Interact with nearest NPC or drop |
| Q | Open / close the quest journal |
| N | Centurion talents (unlocks at level 2) |
| 1–6 | Use the corresponding assigned action slot |
| I | Character, 20-cell pack and eleven equipment slots |
| M | Region map (unavailable in the Dark Woods) |
| U | Testing shortcut: grant 15 talent points |
| Mouse wheel | Zoom |
| Esc | Close a panel / pause menu |
| F5 | Save journey |

Speak with **Warden Elric** to accept **The Crow's Captive**, then follow the road
northeast to the Old Watchtower. Click its north-facing door (or approach and press
E), defeat Darius Crowbane inside and collect the Warwick Cellar Key. Return it to
Elric for 50 gold. Accept **A Lord Beneath the Stones** from Elric next: enter
Warwick's southeast ruins, defeat Jailor Brutus, unlock the rear cell and speak
with Lord Kasparov. You return to town with the lord, 10 gold and his Green
Family Seal (+5 vitality). Darius also drops the White +2 armor Outlaw's Mantle.
Mara buys spare gear and sells upgrades and tonics. Iona heals freely; she no
longer resets encounters. Elric's quest rewards 50 gold only. Enemies signal attacks before they land; arrows can be evaded.
Death costs 10% of carried gold, rounded up, and returns you to town with gear
and objective progress intact, including when dying inside the tower. Inventory,
dialogue and map panels pause combat. Resting restores one vitality every two
seconds after four seconds without combat, only while no enemy is chasing you.

After defeating Vane and Bloodfang, hand **Into the Lion's Den** in to Kasparov.
Speak with **Warden Elric** and confirm travel to **The Hollowmere Marshes**.
The expedition arrives at Lanternwatch Camp: Rowan trades equipment and tonics,
Maelin heals, and Tamsin resets talents for 100 gold. Elric also offers return
travel to Briarwatch, where Master Oswin provides the same talent reset service.
Hollowmere contains seventy crocodiles, Marsh Widows and Broodqueens, seven
wilderness landmarks, five caches holding 10–20 gold, fourteen new equipment
pieces, two bridge crossings, and distinct camp and wilderness soundtracks.
Its story continues through Elric's dialogue; no marsh quests are offered yet.

Each **Crit Rating** grants 1% critical chance, starting at zero. Critical hits
deal twice the damage and show larger yellow numbers. Gear can also increase
movement speed. Widow poison and Broodqueen webs interact with existing wards
and Unshackled. Chests scatter their contents onto the ground for collection.

Click an item to inspect it; double-click or right-click to equip/use it. Drag
pack items onto compatible gear slots, or drag equipped gear back to the pack.
Six action slots start empty: click to assign a learned ability or consumable,
drag an active talent from its tree or a potion from the pack, or
right-click to clear. Drag between belt slots to swap bindings. Tonic heals 50
vitality over five seconds; Greater Tonic heals 100 over five seconds. Recovery
does not stack. See [current balance and item tables](docs/BALANCE.md).

Slots cover head, shoulders, armor, gloves, belt, boots, amulet, two rings, main
hand and off hand. Two-handed weapons reserve both hands, with safe pack-space
checks before swapping. The M map reveals terrain as you explore and keeps only the active quest objective
pin. The Dark Woods has no map. There is no player marker or minimap. Exploration persists in your save.
Gold balances appear in the inventory and vendor, not on the main HUD.
Equipment is visible on the Centurion and the portrait.
Targeted attacks continue closing on retreating enemies; Shift-click remains an
attack in place.

## Saves

The single local character uses Godot's `user://briarwatch_v1.json`, normally
`%APPDATA%/Godot/app_userdata/Briarwatch/`. A previous valid save is kept as `.bak`.
Loading resumes at full health in Briarwatch or Lanternwatch Camp, according to
the saved recovery region. Existing saves default to Briarwatch. Inventory, equipment, gold, quest state,
defeated spawn IDs, action bindings, explored map cells and uncollected drops persist
separately for each region. The key has its own unsellable quest pouch and takes
no bag space. Injured living
enemies reset. Levels, EXP, ranks, testing talent-point grants, cooldowns and the opened rescue cell persist.
Death during an unfinished Garrick/Bloodfang fight resets both bosses and locks
Bloodfang back in his cage. Maze kills, opened chests and floor loot remain;
bosses and summoned wolves only grant their loot and EXP once per character.
If the ring cannot fit, make space and use **Claim reward** in the pack header.
Old saves receive one-time EXP credit for recorded kills; no progress reset is needed.
No personal saves enter Git. Copy the save and backup separately between PCs if
you want to continue the same character. To start over, close the game and move
both files to a backup folder.

Saves from earlier Briarwatch builds migrate old camp-clear quest state to the
current key objective while preserving equipment, gold and outdoor defeats.

## Repository workflow

The repository uses `main` as its default branch. For a private GitHub remote, run:

```text
git remote add origin <your-private-repository-url>
git push -u origin main
```

On another PC: clone it, download the pinned Godot version (or run setup), import
`project.godot`, and press F5. Commit `.gd`, `.gd.uid`, `.tscn`, `.tres`, source
assets and documentation. Do not commit `.godot/`, `.tools/`, test captures, exports
or save files. Pull before editing; prefer feature branches. Avoid two people
editing the same `.tscn` simultaneously. If `origin` already exists, use that
configured remote rather than adding a duplicate. Never commit credentials.

## Layout and checks

- `scenes/`: composition roots, reusable actors, visually authored region.
- `src/`: focused gameplay components, AI, UI, presentation and persistence.
- `content/`: Inspector-editable attack, enemy, item, NPC and quest resources.
- `assets/`: project icon, terrain/foliage shaders and painted UI textures.
- `tools/`: pinned setup/launch scripts and Godot editor validation script.
- `tests/`: integrated gameplay checks and rendered screenshot capture.
- `docs/`: game direction, architecture, editing workflow and verification notes.

```powershell
.\tools\launch.ps1 -Mode test
.\tools\launch.ps1 -Mode capture
```

Tests use `--test` to isolate themselves from real player saves. Captures go to
ignored `test-results/`. See [level editing](docs/LEVEL_EDITING.md) and
[verification](docs/TESTING.md). Your supplied development instructions are
preserved verbatim in `Project development instructions.txt`.

The visual overhaul uses slate-roof timber buildings, layered stylized characters,
jagged woodland silhouettes, wind-driven grass, warm lanterns and a bronze-framed
interface. See [visual direction and asset prompts](docs/VISUAL_DIRECTION.md) and
[asset provenance](docs/ASSETS.md) before extending the art library.

## Levels and talents

N opens two Centurion trees from level 2. Each level awards one point; every
connected prerequisite must be fully ranked. Learned abilities bind to slots 1–6.
The Briar March storyline provides 130 EXP before Bloodfang's summoned packs,
or 134 EXP including both pairs of Greyfangs. Hollowmere adds 176 EXP, for 310
across both regions including summons. Overflow is discarded at each level-up.
The full level curve and
talent rules are in [progression and combat rules](docs/PROGRESSION.md).
