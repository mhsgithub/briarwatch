"""Offline authoring source for the chapel's native scenes and Resources.

Owns only the new chapel/patrol content. Does not regenerate Hollowmere scenery.
Run with Python 3 from any directory; no third-party packages are required.
"""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def write(path, text):
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text.strip() + '\n', encoding='utf-8')

def resource(kind, script, fields, refs=''):
    return f'''[gd_resource type="Resource" script_class="{kind}" format=3]
[ext_resource type="Script" path="res://src/data/{script}.gd" id="script"]
{refs}
[resource]
script = ExtResource("script")
{fields}
'''

def author():
    for ident, damage, reach, windup, cooldown, extra in [
        ('zombie',24,2.15,.65,1.65,''),
        ('skeletal_arrow',30,11,.85,2.1,'projectile = true\nprojectile_speed = 14.0'),
        ('risen_sword',35,2.6,.6,1.6,''),
        ('rotting_cleave',60,3.6,1,2,'arc_degrees = 110.0'),
    ]:
        write(f'content/attacks/{ident}.tres',resource('AttackDefinition','attack_definition',f'id = &"{ident}"\ndamage = {damage}.0\nreach = {reach}\nwindup = {windup}\ncooldown = {cooldown}\n{extra}'))
    for ident, name, hp, speed, accuracy, xp, attack, behavior, profile in [
        ('zombie','Zombie',120,2.25,.8,2,'zombie','melee','zombie'),
        ('skeletal_archer','Skeletal Archer',100,2.64,1,3,'skeletal_arrow','archer','skeleton'),
    ]:
        write(f'content/enemies/{ident}.tres',resource('EnemyDefinition','enemy_definition',f'''id = &"{ident}"
display_name = "{name}"
appearance = "{ident}"
behavior = "{behavior}"
audio_profile = "{profile}"
max_health = {hp}.0
move_speed = {speed}
hit_chance = {accuracy}
experience = {xp}
aggro_radius = 10.0
leash_radius = 28.0
attack = ExtResource("attack")
loot_table = ExtResource("loot")''',f'''[ext_resource type="Resource" path="res://content/attacks/{attack}.tres" id="attack"]
[ext_resource type="Resource" path="res://content/loot/marsh_wildlife.tres" id="loot"]'''))
    write('content/items/captains_breastplate.tres',resource('ItemDefinition','item_definition','''id = &"captains_breastplate"
display_name = "Captain's Breastplate"
description = "Lanternwatch steel, its reed-and-lantern crest scarred by a darkness no forge could temper."
slot = "body"
tier = "green"
armor_bonus = 5.0
vitality_bonus = 5.0
crit_rating = 1.0
price = 160
sell_price = 16
appearance = "captain_plate"
icon = ExtResource("icon")
tint = Color(0.24, 0.36, 0.36, 1)''','[ext_resource type="Texture2D" path="res://assets/ui/captains_breastplate.svg" id="icon"]'))
    write('content/loot/risen_soldier.tres','''[gd_resource type="Resource" script_class="LootTable" format=3]
[ext_resource type="Script" path="res://src/data/loot_table.gd" id="table"]
[ext_resource type="Script" path="res://src/data/loot_entry.gd" id="entry"]
[ext_resource type="Resource" path="res://content/items/captains_breastplate.tres" id="item"]
[sub_resource type="Resource" id="drop"]
script = ExtResource("entry")
item = ExtResource("item")
chance = 1.0
[resource]
script = ExtResource("table")
entries = Array[ExtResource("entry")]([SubResource("drop")])''')
    write('content/enemies/risen_soldier.tres',resource('EnemyDefinition','enemy_definition','''id = &"risen_soldier"
display_name = "Risen Soldier"
appearance = "risen_soldier"
audio_profile = "zombie"
voice_pitch = 0.76
max_health = 270.0
move_speed = 2.7
hit_chance = 1.0
experience = 12
is_boss = true
aggro_radius = 18.0
leash_radius = 80.0
visual_scale = 1.28
collision_radius = 0.5
attack = ExtResource("attack")
commander = SubResource("cleave_kit")
risen = SubResource("risen_kit")
loot_table = ExtResource("loot")''','''[ext_resource type="Resource" path="res://content/attacks/risen_sword.tres" id="attack"]
[ext_resource type="Resource" path="res://content/attacks/rotting_cleave.tres" id="cleave"]
[ext_resource type="Resource" path="res://content/loot/risen_soldier.tres" id="loot"]
[ext_resource type="Script" path="res://src/data/commander_definition.gd" id="commander"]
[ext_resource type="Script" path="res://src/data/risen_definition.gd" id="risen"]
[sub_resource type="Resource" id="cleave_kit"]
script = ExtResource("commander")
cleave = ExtResource("cleave")
cleave_cooldown = Vector2(8,12)
warning_color = Color(0.46,0.68,0.24,0.42)
warning_cue = "rotting_warning"
release_cue = "rotting_cleave"
voice_pitch = 1.0
[sub_resource type="Resource" id="risen_kit"]
script = ExtResource("risen")'''))
    write('content/npcs/corvin.tres',resource('NpcDefinition','npc_definition','''id = &"corvin"
display_name = "Sergeant Corvin Marr"
title = "Last of the Lanternwatch patrol"
service = "companion"
appearance = "corvin"
greeting = "Keep your voice down. They were dead before they reached us... and they kept coming."
tint = Color(0.27,0.38,0.37,1)'''))
    write('content/quests/drowned_patrol.tres',resource('QuestDefinition','quest_definition','''id = &"drowned_patrol"
title = "The Drowned Patrol"
giver_region = &"hollowmere"
giver_npc = "elric"
handin_region = &"hollowmere"
handin_npc = "elric"
target_region = &"chapel_crypts"
target_encounter = &"risen_soldier"
reward_gold = 50
offer_objective = "Speak with Warden Elric at Lanternwatch Camp."
offer_dialogue = "This was fertile country once: fishing villages, peat cutters, herb gardens along the pilgrimage road. The marsh-priests kept their own counsel at the chapel. Years ago, something old began to stir beneath the water. Now travelers vanish and supply boats drift in empty. Sergeant Corvin Marr took a patrol to Siltwater Landing, just north of camp. None have returned. Find them. Bring me word of what is happening here."
description = "Warden Elric sent Sergeant Corvin Marr and a Lanternwatch patrol to investigate missing travelers and abandoned supply boats at Siltwater Landing. The patrol never returned. Search the landing north of camp and discover their fate.\n\nThe wetland once sustained villages and pilgrims. Now its old roads lead through drowned fields, and something ancient stirs beneath them."
objective = "Find the missing patrol at Siltwater Landing, north of camp."
return_objective = "Return to Warden Elric at Lanternwatch. Tell him of Corvin and Malrec's ritual."
entrance_label = "The Sunken Chapel"
accept_text = "I will find the patrol"
progress_dialogue = "Corvin knows this marsh better than any of us. If he is alive, he will have found cover near the landing."
handin_dialogue = "Corvin... He would have dragged every one of them home if he could. You gave him the only peace that remained. Malrec Veyne knew his name, and this woman he summoned is already loose. Then the dead at the landing were only the beginning. Take this for your service. I will double the watch and send word to Kasparov. We must learn what Veyne has brought into the marsh."
completed_dialogue = "Corvin and his patrol will be remembered. Keep your weapons close. Whatever Veyne summoned is still out there."
completion_text = "Elric knows the truth. Corvin rests, but Malrec's summoned presence remains at large."
stages = Array[ExtResource("stage_script")]([SubResource("patrol"),SubResource("chapel"),SubResource("ritual"),SubResource("soldier")])''','''[ext_resource type="Script" path="res://src/data/quest_stage.gd" id="stage_script"]
[sub_resource type="Resource" id="patrol"]
script = ExtResource("stage_script")
id = &"find_patrol"
objective = "Search Siltwater Landing north of camp. Speak with any survivors."
region = &"hollowmere"
target_path = NodePath("PointsOfInterest/SiltwaterLanding")
label = "The missing patrol"
[sub_resource type="Resource" id="chapel"]
script = ExtResource("stage_script")
id = &"enter_crypts"
objective = "Investigate the Sunken Chapel with Corvin. Find a way beneath its stones."
region = &"hollowmere"
target_path = NodePath("PatrolSite/ChapelLever")
label = "The Sunken Chapel"
[sub_resource type="Resource" id="ritual"]
script = ExtResource("stage_script")
id = &"witness_ritual"
objective = "Search the chapel crypts with Corvin. Find the source of the risen dead."
region = &"chapel_crypts"
target_path = NodePath("CryptRitual")
label = "Investigate the crypts"
[sub_resource type="Resource" id="soldier"]
script = ExtResource("stage_script")
id = &"defeat_soldier"
objective = "Lay the Risen Soldier to rest."
region = &"chapel_crypts"
target_path = NodePath("Encounters/risen_soldier")
label = "The Risen Soldier"'''))
    author_scene()

def author_scene():
    text = '''[gd_scene format=3]
[ext_resource type="Script" path="res://src/world/region.gd" id="region"]
[ext_resource type="Script" path="res://src/world/crypt_chamber.gd" id="chamber"]
[ext_resource type="Script" path="res://src/world/region_portal.gd" id="portal"]
[ext_resource type="Script" path="res://src/world/encounter.gd" id="encounter"]
[ext_resource type="Script" path="res://src/world/enemy_spawn.gd" id="spawn"]
[ext_resource type="Script" path="res://src/world/crypt_ritual.gd" id="ritual"]
[ext_resource type="Script" path="res://src/presentation/necromancer_visual.gd" id="malrec"]
[ext_resource type="Script" path="res://src/presentation/ritual_visual.gd" id="ritual_art"]
[ext_resource type="Resource" path="res://content/enemies/zombie.tres" id="zombie"]
[ext_resource type="Resource" path="res://content/enemies/skeletal_archer.tres" id="skeleton"]
[ext_resource type="Resource" path="res://content/enemies/risen_soldier.tres" id="soldier"]
[sub_resource type="NavigationMesh" id="navmesh"]
geometry_parsed_geometry_type = 1
geometry_collision_mask = 1
cell_size = 0.3
cell_height = 0.1
agent_height = 2.0
agent_radius = 0.6
agent_max_climb = 0.5
[node name="ChapelCrypts" type="Node3D"]
script = ExtResource("region")
region_id = &"chapel_crypts"
display_name = "The Chapel Crypts"
interior = true
recovery_region = &"hollowmere"
hub_name = "Lanternwatch Camp"
music_track = &"chapel_crypts"
interior_ambient = 0.25
interior_sun = 0.16
map_bounds = Rect2(-23,-64,48,97)
[node name="NavigationRegion" type="NavigationRegion3D" parent="."]
navigation_mesh = SubResource("navmesh")
[node name="Scenery" type="Node3D" parent="NavigationRegion"]
[node name="ProcessionalHall" type="Node3D" parent="NavigationRegion/Scenery"]
script = ExtResource("chamber")
extent = Vector2(10,60)
north_opening = 8.0
south_opening = 3.2
west_openings = PackedVector2Array(11,4.2,-23,4.2)
east_openings = PackedVector2Array(-8,4.2)
decor = "hall"
[node name="Reliquary" type="Node3D" parent="NavigationRegion/Scenery"]
position = Vector3(-12,0,11)
script = ExtResource("chamber")
extent = Vector2(14,14)
east_openings = PackedVector2Array(0,4.2)
decor = "tombs"
[node name="Ossuary" type="Node3D" parent="NavigationRegion/Scenery"]
position = Vector3(13,0,-8)
script = ExtResource("chamber")
extent = Vector2(16,14)
west_openings = PackedVector2Array(0,4.2)
decor = "bones"
[node name="VigilChamber" type="Node3D" parent="NavigationRegion/Scenery"]
position = Vector3(-12,0,-23)
script = ExtResource("chamber")
extent = Vector2(14,12)
east_openings = PackedVector2Array(0,4.2)
decor = "tombs"
[node name="RitualSanctum" type="Node3D" parent="NavigationRegion/Scenery"]
position = Vector3(0,0,-45)
script = ExtResource("chamber")
extent = Vector2(34,30)
south_opening = 8.0
decor = "sanctum"
[node name="Actors" type="Node3D" parent="."]
[node name="NPCs" type="Node3D" parent="."]
[node name="PlayerSpawn" type="Marker3D" parent="."]
position = Vector3(0,0.1,27)
[node name="Portals" type="Node3D" parent="."]
[node name="Exit" type="Node3D" parent="Portals"]
position = Vector3(0,0,29.3)
script = ExtResource("portal")
display_name = "Ascend to the Sunken Chapel"
destination = &"hollowmere"
arrival = &"chapel"
[node name="CryptRitual" type="Node3D" parent="."]
position = Vector3(0,0,-47)
script = ExtResource("ritual")
[node name="Malrec" type="Node3D" parent="CryptRitual"]
position = Vector3(0,0.15,-3)
rotation = Vector3(0,3.14159,0)
script = ExtResource("malrec")
[node name="Ritual" type="Node3D" parent="CryptRitual"]
script = ExtResource("ritual_art")
[node name="Focus" type="Marker3D" parent="CryptRitual"]
position = Vector3(0,0,5)
[node name="Reinforcements" type="Node3D" parent="."]
[node name="SkeletalArcher" type="Marker3D" parent="Reinforcements"]
position = Vector3(0,0.1,-28)
script = ExtResource("spawn")
spawn_id = &"crypt_half_health_archer"
definition = ExtResource("skeleton")
[node name="Encounters" type="Node3D" parent="."]
'''
    groups = [
        ('entrance',[(0,18),(2,14),(-2,13)],[]),
        ('reliquary',[(-9,12),(-13,14),(-16,8),(-11,7)],[(-12,16)]),
        ('hall',[(-2,3),(2,-1),(0,-6)],[]),
        ('ossuary',[(8,-7),(13,-4),(17,-10),(10,-12)],[(17,-4)]),
        ('vigil',[(-8,-22),(-13,-20),(-15,-26),(-10,-26)],[(-12,-19)]),
        ('last_watch',[(-2,-20),(2,-25)],[(2,-29)]),
    ]
    for name,zombies,archers in groups:
        text += f'\n[node name="{name}" type="Node3D" parent="Encounters"]\nscript = ExtResource("encounter")\nencounter_id = &"crypt_{name}"\ndisplay_name = "{name.replace("_"," ").title()}"\n'
        for i, (kind, p) in enumerate([('zombie',p) for p in zombies]+[('skeleton',p) for p in archers]):
            x,z=p
            text += f'[node name="{kind}{i}" type="Marker3D" parent="Encounters/{name}"]\nposition = Vector3({x},0.1,{z})\nscript = ExtResource("spawn")\nspawn_id = &"crypt_{name}_{i}"\ndefinition = ExtResource("{kind}")\n'
    text += '''[node name="risen_soldier" type="Node3D" parent="Encounters"]
position = Vector3(-2,0,-39)
script = ExtResource("encounter")
encounter_id = &"risen_soldier"
display_name = "Risen Soldier"
[node name="Corvin" type="Marker3D" parent="Encounters/risen_soldier"]
position = Vector3(0,0.1,0)
script = ExtResource("spawn")
spawn_id = &"crypt_risen_corvin"
definition = ExtResource("soldier")'''
    write('scenes/world/chapel_crypts.tscn',text)

def install_hollowmere():
    """Idempotent additive overlay; also called after Hollowmere authoring."""
    p=ROOT/'scenes/world/hollowmere.tscn'
    text=p.read_text(encoding='utf-8')
    if 'id="patrol_site"' in text: return
    text=text.replace('[sub_resource type="NavigationMesh"', '[ext_resource type="PackedScene" path="res://scenes/world/patrol_site.tscn" id="patrol_site"]\n[ext_resource type="Script" path="res://src/world/region_portal.gd" id="crypt_portal"]\n[sub_resource type="NavigationMesh"',1)
    text+='''
[node name="PatrolSite" parent="." instance=ExtResource("patrol_site")]
[node name="Arrivals" type="Node3D" parent="."]
[node name="chapel" type="Marker3D" parent="Arrivals"]
position = Vector3(42,0.1,29)
[node name="Portals" type="Node3D" parent="."]
[node name="ChapelCrypts" type="Node3D" parent="Portals"]
position = Vector3(42,0,31)
script = ExtResource("crypt_portal")
display_name = "Descend beneath the chapel"
destination = &"chapel_crypts"
required_quest = &"drowned_patrol"
required_flag = "chapel_open"
locked_message = "The stair is sealed. Find the chapel's lever."
appearance = "stairs"
'''
    p.write_text(text,encoding='utf-8')

if __name__ == '__main__':
    author()
    install_hollowmere()
    from author_darkmere import link_content
    link_content()
