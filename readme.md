# Briarwatch

An original single-player PC action RPG set in a weathered frontier of timber
villages, old stone defenses and dangerous woodland roads. This first milestone
is a playable foundation: **one 160 × 144 metre region, 24 enemies in eight
encounters, three useful NPCs, sword combat, loot, equipment, trading, recovery,
and a small persistent quest**.

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
| Q | Drink a field tonic |
| I | Inventory and three equipment slots |
| M | Region map |
| Mouse wheel | Zoom |
| Esc | Close a panel / pause menu |
| F5 | Save journey |

Speak with **Warden Elric**, then follow the road northeast to the Old Watchtower.
Mara buys spare gear and sells upgrades and tonics. Iona heals freely and can
refresh the region's encounters. Rest removes uncollected loot, as stated in her
service panel. Enemies signal attacks before they land; arrows can be evaded.
Death costs 10% of carried crowns, rounded up, and returns you to town with gear
and objective progress intact. Inventory, dialogue and map panels pause combat.

## Saves

The single local character uses Godot's `user://briarwatch_v1.json`, normally
`%APPDATA%/Godot/app_userdata/Briarwatch/`. A previous valid save is kept as `.bak`.
Loading resumes in town at full health. Inventory, equipment, crowns, quest state,
defeated spawn IDs and uncollected drops persist. Injured living enemies reset.
No personal saves enter Git. Copy the save and backup separately between PCs if
you want to continue the same character. To start over, close the game and move
both files to a backup folder.

## Repository workflow

The repository is initialized on `main`. Create a **private** empty remote on your
preferred Git host, then run:

```text
git remote add origin <your-private-repository-url>
git push -u origin main
```

On another PC: clone it, download the pinned Godot version (or run setup), import
`project.godot`, and press F5. Commit `.gd`, `.gd.uid`, `.tscn`, `.tres`, source
assets and documentation. Do not commit `.godot/`, `.tools/`, test captures, exports
or save files. Pull before editing; prefer feature branches. Avoid two people
editing the same `.tscn` simultaneously. No remote or credentials are configured
by this milestone.

## Layout and checks

- `scenes/`: composition roots, reusable actors, visually authored region.
- `src/`: focused gameplay components, AI, UI, presentation and persistence.
- `content/`: Inspector-editable attack, enemy, item, NPC and quest resources.
- `assets/`: original project icon; world art is original code-built geometry.
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
