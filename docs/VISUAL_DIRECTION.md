# Briarwatch visual direction

## Shipped visual language

The direction is stylized dark medieval fantasy: moss, slate, timber, worn iron,
teal cloth, amber light and restrained bronze ornament. Faceted silhouettes and
readable negative space take priority over realism. The world remains authored
in Godot and its art components remain separate from gameplay logic.

The town uses timber framing, individual slate shingles, chimney courses, lit
windows, masonry wells and warm lanterns. Wilderness props use layered jagged
canopies, roots, faceted rocks, camp cloth and stone ruins. Ground shaders provide
patchy earth and moss, soft dirt-road edges and staggered paving. MultiMesh grass
has subtle wind and avoids roads. Characters have layered armor, articulated
gait, capes and distinct wolf/bow/sword silhouettes. This is procedural stylized
3D with painted UI, not a hand-painted 2D world or a skeletal-animation library.

The interface uses charcoal enamel and bronze frames, serif headings, warm ivory
body text, a crimson vitality orb and a compact icon-led action bar. Character
inventory presents the Centurion silhouette between eleven labeled gear slots;
the pack and item details remain visible together. The same theme serves NPCs,
services, recovery and pause. The map draws authored region data. Item tiles
support inspection, tooltips, activation and compatible drag/drop.

## Extending the style

- Keep game rules out of presentation components and authored Resource defaults.
- Prefer adding to existing prop/actor vocabulary; introduce imported meshes or
  skeletons behind those owners when animation/content actually needs them.
- Use a custom item `icon` texture for future assets, or `icon_index` for atlas
  cells. Do not bake item names/numbers into artwork; UI provides accessible text.
- Keep icons centered, bold at 40-70 px display size and away from cell edges.
- Avoid saturated clutter on the ground: characters, hits and loot need contrast.
- Run all sixteen visual captures after changing palette, panel geometry or fonts.

## Shipped painted assets

Generated with the **built-in image-generation tool**, not the fallback CLI.
For the original two assets no reference image or third-party game asset was supplied. Final source files:

- `assets/ui/equipment_atlas.png` — 1254x1254 RGBA, four equal columns/rows.
- `assets/ui/panel_frame.png` — 1536x1024 RGBA, scalable border with transparent center.

The tool returned alpha despite the requested dark background; the game keeps
that alpha and paints its own backing. The exact square output size also differs
from the requested size; atlas coordinates derive from actual dimensions.

| Row | Cell indices and subjects, left to right |
|---|---|
| 1 | 0 old sword; 1 oak shield; 2 coat; 3 Tonic |
| 2 | 4 forged sword; 5 iron shield; 6 mail; 7 warden blade |
| 3 | 8 helmet; 9 shoulders; 10 gloves; 11 belt |
| 4 | 12 boots; 13 amulet; 14 ring; 15 gold |

Cells 8–14 also illustrate empty gear destinations. Cell 4 remains unused legacy
art: the Forged Longsword item has been removed. Current content uses the expansion
atlas below for the new items; definitions, not atlas cells, determine the roster.

### Final atlas prompt

```text
Use case: stylized-concept. Asset type: production inventory icon atlas for original dark medieval fantasy ARPG Briarwatch. Create a square 1024x1024 image divided into an EXACT 4 by 4 grid of equal 256 square cells, with no visible grid borders. Every cell uniform almost black green #111919 background. One centered painted object per cell, fully inside central 70 percent with generous empty margins. Row 1 left to right: weathered steel longsword diagonal; ironbound oak kite shield; padded teal quilted tunic; small crimson healing potion with cork. Row 2: forged silver longsword with bronze hilt; riveted steel kite shield; chainmail hauberk; ornate silver warden sword with amber gem. Row 3: closed medieval steel helmet; pair of broad steel shoulder pauldrons; leather and steel gauntlets; wide leather belt with bronze buckle. Row 4: pair of heavy leather boots; amber amulet on chain; gold signet ring with jade stone; small pile of gold coins. Style: beautifully hand-painted stylized fantasy inventory art, chunky readable silhouettes, brush strokes, bold dark ink contours, sharp warm edge highlights, cool desaturated steel, worn bronze, moody teal shadows. Not realistic, not plastic 3D, not cute. Consistent scale and lighting. No lettering, no numbers, no watermark, no decorative backgrounds. Precisely uniform aligned 4x4 atlas layout.
```

### Final frame prompt

```text
Use case: stylized-concept. Asset type: reusable nine-slice inventory window frame texture for original dark fantasy game Briarwatch. Landscape 3:2 rectangular frame seen straight-on, perfectly flat UI asset, centered and filling canvas to edges. Weathered blackened bronze narrow outer frame, delicately engraved thorn-vine corner ornaments, subtle rivets, warm pale brass bevel highlights, slim double inner border. Frame around a completely plain solid deep charcoal teal #111919 rectangular center taking 88 percent of width and 84 percent of height. No illustration, no characters, no writing, no icons, no title, no objects in the center, no watermark. Keep all ornament entirely within outer 65 pixels, center completely uniform for text readability. Hand-painted stylized medieval game interface, dark enamel and etched metal, beautiful restrained craft, angular elegant corners, not realistic photography, not modern dashboard, not overly baroque. The outer edge of the frame meets all four canvas edges. This is an actual scalable panel asset not a screenshot mockup.
```

## Approved direction and equipment expansion

Preserve this approved art and character/pack design going forward. Diablo II is
the inspiration for readable combat, loot and exploration, not copied franchise
art. Equipped gear is visible in both the world and portrait; an unequipped
Centurion wears simple clothing. Bandits wear cloth/leather, not knight armor.
Campfires use moving faceted flames, rising embers and warm fluctuating light.
The camera never rotates with locomotion. Close scenery fades smoothly.

New source: `assets/ui/field_gear_atlas.png`, generated with the **built-in
image-generation tool**, using our original atlas as the style reference. No
external franchise assets were used. ArtTheme maps indices 16–31 into this atlas.

| Row | Cell indices and subjects, left to right |
|---|---|
| 1 | 16 Greater Tonic; 17 Watchkeeper Helmet; 18 Outrider Gloves; 19 Outrider Belt |
| 2 | 20 Outrider Boots; 21 Guardian’s Amulet; 22 Worn Leather Gloves; 23 Worn Leather Belt |
| 3 | 24 Ragged Cloth Hood; 25 Stiched Leather Vest; 26 Ragged Boots; 27 Pitchfork |
| 4 | 28 gold pile; 29 spare sword; 30 spare Tonic; 31 spare coat |

The final row provides spare art only, not extra item definitions.

### Final expansion atlas prompt

```text
Use case: stylized-concept. Asset type: production 4x4 equipment icon atlas for Briarwatch. Image 1 is a style reference only, do not modify it. Create a NEW square atlas with EXACTLY four equal columns and four equal rows, 16 equal square cells, no grid lines. Match the reference hand-painted dark medieval fantasy style, generous padding, chunky readable silhouettes, desaturated metal and leather, warm edge highlights, dark teal shadows. Each item isolated centered within central 70 percent of its cell on genuinely transparent background. Row 1 left to right: large round crimson potion bottle with metal neck and cork; closed steel watchkeeper helmet with narrow eye slit; pair of reinforced dark leather outrider gloves; wide dark leather outrider belt with bronze buckle. Row 2: reinforced outrider boots; guardian amulet with green gemstone on bronze chain; pair of worn plain brown leather gloves; narrow worn brown leather belt with simple iron buckle. Row 3: ragged charcoal cloth hood with face opening; stitched brown leather vest; pair of ragged simple brown boots; a long wooden farming pitchfork with THREE iron tines diagonal fully visible. Row 4: small gold coin pile; a plain steel sword; a small crimson tonic bottle; quilted teal padded coat. No text, lettering, labels, watermark, borders, characters or background scenes. Keep objects entirely within their individual cells and consistently scaled. A game asset sheet, not a screenshot mockup.
```
