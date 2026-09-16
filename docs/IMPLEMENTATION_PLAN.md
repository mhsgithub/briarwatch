# Milestone decisions

Briarwatch is an original single-player frontier ARPG. Use Godot 4.7.2 stable,
typed GDScript, native scenes/resources, Compatibility rendering, and orthographic
3D. No external packages, online services, credentials, or environment variables
are needed to run the game.

Implementation order:
1. Resource contracts, health/combat, inventory, save format.
2. Composed player/enemy scenes and navigation, readable original primitive art.
3. Editor-visible region, spawn markers, NPC services, objective and loot loop.
4. UI, persistence, feedback, testing and final documentation.

Ownership: Session coordinates region/player/UI and saves; it does not calculate
damage, own AI decisions, define content, or render the world. Region owns its
navigation and actors. Resources are immutable shared definitions. Per-instance
health/damage overrides are copied into runtime state. All resource paths use res://.

The level is an authored .tscn, with @tool props, NPCs and spawn markers visible
in the standard 3D editor. Navigation uses Godot's native navigation bake and
NavigationAgent3D. Small resource classes provide future seams without implementing
unused skill trees, damage resistances, crafting or streaming systems.
