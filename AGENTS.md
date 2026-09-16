# Project development

Work carefully, thoroughly and systematically. Favor maintainable architecture,
extensibility and reliable gameplay before visual polish. Keep additions practical:
this is a foundation for a larger ARPG, not a reason to build unused systems.

Read `readme.md`, `docs/GAME.md` and `docs/ARCHITECTURE.md` before extending the game.
The user's original instructions are preserved in `Project development instructions.txt`.

- Use the pinned stable Godot version, typed GDScript and native scenes/resources.
- Keep content in resources and authored scenes, not individual behavior scripts.
- Preserve stable item, spawn and encounter IDs used by saves.
- Keep shared definitions immutable during gameplay; instance state belongs to components.
- No machine-specific absolute paths or untracked runtime dependencies.
- This offline milestone needs no credentials or environment variables. If a future
  feature genuinely requires a service, create portable configuration and request
  the required credentials; never embed secrets in source or commit them.
- Run `tools/launch.ps1 -Mode test` after relevant gameplay changes. Use `-Mode capture`
  and inspect images after visible UI/presentation changes. `--test` isolates saves.
- Keep documentation consistent with the implementation and leave Git understandable.
