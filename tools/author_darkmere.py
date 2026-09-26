"""Offline native content authoring for Hollowmere's concluding quests.
Only owns its new resources/scenes and additive Hollowmere overlay.
"""
from pathlib import Path
from author_chapel import write, resource
ROOT=Path(__file__).resolve().parents[1]

def author():
    for ident,name,slot,tier,fields in [
        ('soldiers_pauldrons',"Soldier's Pauldrons",'shoulders','green','armor_bonus = 4.0\nstrength_bonus = 1.0\ncrit_rating = 1.0\nappearance = "reinforced"'),
        ('black_reliquary','The Black Reliquary','ring','blue','strength_bonus = 2.0\nvitality_bonus = 20.0\nlife_steal_chance = 0.05\nlife_steal_amount = 3.0'),
        ('veyne_letter','A Dark Missive','quest','white','description = "A violet seal still pulses against the parchment. Bring the letter to Warden Elric."')]:
        write(f'content/items/{ident}.tres',resource('ItemDefinition','item_definition',f'''id = &"{ident}"
display_name = "{name}"
slot = "{slot}"
tier = "{tier}"
price = 180
sell_price = 16
icon = ExtResource("icon")
{fields}''',f'[ext_resource type="Texture2D" path="res://assets/ui/{ident}.svg" id="icon"]'))
    write('content/attacks/zombie_brute.tres',resource('AttackDefinition','attack_definition','id = &"zombie_brute"\ndamage = 40.0\nreach = 2.6\nwindup = 0.7\ncooldown = 1.8'))
    write('content/attacks/ritualist.tres',resource('AttackDefinition','attack_definition','id = &"ritualist"\ndamage = 0.0'))
    for ident,name,hp,xp,look,attack,extra in [
        ('zombie_brute','Zombie Brute',200,4,'zombie_brute','zombie_brute','move_speed = 2.6\nvoice_pitch = 0.67\ncollision_radius = 0.65\ncollision_height = 2.2\ncharge = SubResource("charge")\nloot_table = ExtResource("loot")'),
        ('cultist','Bound Cultist',80,0,'cultist','ritualist','passive = true\nmove_speed = 0.0'),
        ('malrec','Malrec Veyne',500,25,'malrec','ritualist','passive = true\nis_boss = true\ncollision_radius = 0.6\ncollision_height = 2.5\nloot_table = ExtResource("loot")')]:
        refs=f'[ext_resource type="Resource" path="res://content/attacks/{attack}.tres" id="attack"]\n'
        if ident=='zombie_brute':
            refs+='[ext_resource type="Resource" path="res://content/loot/marsh_wildlife.tres" id="loot"]\n[ext_resource type="Script" path="res://src/data/charge_definition.gd" id="charge"]\n[sub_resource type="Resource" id="charge"]\nscript = ExtResource("charge")'
        elif ident=='malrec': refs+='[ext_resource type="Resource" path="res://content/loot/malrec.tres" id="loot"]'
        write(f'content/enemies/{ident}.tres',resource('EnemyDefinition','enemy_definition',f'''id = &"{ident}"
display_name = "{name}"
appearance = "{look}"
max_health = {hp}.0
hit_chance = 1.0
experience = {xp}
audio_profile = "{'zombie' if ident=='zombie_brute' else 'occult'}"
attack = ExtResource("attack")
{extra}''',refs))
    write('content/loot/malrec.tres','''[gd_resource type="Resource" script_class="LootTable" format=3]
[ext_resource type="Script" path="res://src/data/loot_table.gd" id="table"]
[ext_resource type="Script" path="res://src/data/loot_entry.gd" id="entry"]
[ext_resource type="Resource" path="res://content/items/black_reliquary.tres" id="ring"]
[sub_resource type="Resource" id="ring"]
script = ExtResource("entry")
item = ExtResource("ring")
chance = 1.0
[resource]
script = ExtResource("table")
entries = Array[ExtResource("entry")]([SubResource("ring")])''')
    write('content/quests/unseen_hand.tres',resource('QuestDefinition','quest_definition','''id = &"unseen_hand"
title = "The Unseen Hand"
giver_region = &"hollowmere"
handin_region = &"hollowmere"
target_region = &"hollowmere"
show_objective_marker = false
required_item = &"veyne_letter"
reward_gold = 0
reward_item = ExtResource("reward")
next_quest = ExtResource("next")
offer_objective = "Speak with Warden Elric at Lanternwatch."
offer_dialogue = "Veyne knew Corvin's name. He had corpses waiting before our patrol reached the landing. That was no chance ambush. Someone has been laying a path through this marsh. Search the Pilgrim Graves, the Drowned Tollhouse and the Old Beacon. Our scouts saw strange light at all three. Find the traces he left, and bring me anything that tells us where he hides. We must end this before another patrol walks into his hands."
description = "Malrec Veyne was prepared for Corvin's patrol. Investigate the Pilgrim Graves, the Drowned Tollhouse and the Old Beacon in any order. Look for dark magical marks and examine each one. Recover any evidence of the necromancer's whereabouts and return it to Elric."
objective = "Find the necromancer's whereabouts. Investigate the three sites and recover his orders."
return_objective = "Bring the dark missive to Warden Elric at Lanternwatch."
accept_text = "I will follow his traces"
progress_dialogue = "The graves, the tollhouse and the beacon. Look for the same magic you saw beneath the chapel. Veyne prepared one ambush; expect him to have prepared more."
handin_dialogue = "This seal... it is still warm. These were orders, carried by a corpse. Corvin was being watched from the moment he left camp. Take these pauldrons. You will need them when we find the hand behind this. Let me read what Veyne thought no living soul would see."
completed_dialogue = "The letter has given us the name of his refuge."
completion_text = "Veyne's orders are in Elric's hands. Soldier's Pauldrons received."''','''[ext_resource type="Resource" path="res://content/items/soldiers_pauldrons.tres" id="reward"]
[ext_resource type="Resource" path="res://content/quests/darkmere.tres" id="next"]'''))
    write('content/quests/darkmere.tres',resource('QuestDefinition','quest_definition','''id = &"darkmere"
title = "The Last Light of Darkmere"
giver_region = &"hollowmere"
handin_region = &"hollowmere"
target_region = &"darkmere_sanctum"
target_encounter = &"malrec"
reward_gold = 50
entrance_label = "Darkmere Hold"
offer_objective = "Hear what Elric has learned from Veyne's letter."
offer_dialogue = "Darkmere Hold. The old keep at the northwest end of the road. These orders direct the dead there, and speak of a woman who has crossed beyond the marsh. Veyne remains behind to close the way. Whatever he is protecting, we cannot let him finish. Enter the hold and put an end to his work. For Corvin, and everyone who never reached our lanterns."
description = "The dark missive reveals Malrec Veyne's refuge: Darkmere Hold, an abandoned keep deep in the northwest marsh. Enter the ruined keep, find Veyne and defeat him, then return to Warden Elric."
objective = "Enter Darkmere Hold in the northwest. Find Malrec Veyne and defeat him."
return_objective = "Malrec Veyne is dead. Return to Warden Elric at Lanternwatch."
accept_text = "Veyne will answer for the patrol"
progress_dialogue = "Follow the western road past the Widow's Weald, then take its northern end to Darkmere. The walls are broken, but the old gate still stands."
handin_dialogue = "Then Corvin's murderer is gone. We can recover the fallen and open the road again. But Veyne said she had already crossed the water... I fear the silence you bought us is only a little time. For now, Lanternwatch will burn through the night. Rest. The marsh owes you that much."
completed_dialogue = "The dead have fallen silent around Darkmere. We will hold this road while we learn what passed beyond it."
completion_text = "Hollowmere's watch endures. Malrec Veyne is defeated."
stages = Array[ExtResource("stage")]([SubResource("enter"),SubResource("ascend"),SubResource("boss")])
''','''[ext_resource type="Script" path="res://src/data/quest_stage.gd" id="stage"]
[sub_resource type="Resource" id="enter"]
script = ExtResource("stage")
id = &"enter_hold"
region = &"hollowmere"
target_path = NodePath("Portals/DarkmereHold")
label = "Darkmere Hold"
objective = "Enter Darkmere Hold at the northwest end of the road."
[sub_resource type="Resource" id="ascend"]
script = ExtResource("stage")
id = &"ascend_hold"
region = &"darkmere_halls"
target_path = NodePath("Portals/UpperFloor")
label = "The upper chamber"
objective = "Find the stairs at the back of the lower halls."
[sub_resource type="Resource" id="boss"]
script = ExtResource("stage")
id = &"defeat_malrec"
region = &"darkmere_sanctum"
target_path = NodePath("MalrecEncounter")
label = "Malrec Veyne"
objective = "Defeat Malrec Veyne in the upper chamber."'''))
    write('content/encounters/malrec.tres',resource('MalrecDefinition','malrec_definition','cultist = ExtResource("cultist")\nzombie = ExtResource("zombie")\nspider = ExtResource("spider")','''[ext_resource type="Resource" path="res://content/enemies/cultist.tres" id="cultist"]
[ext_resource type="Resource" path="res://content/enemies/zombie.tres" id="zombie"]
[ext_resource type="Resource" path="res://content/enemies/marsh_widow.tres" id="spider"]'''))
    scenes()
    overlay()
    link_content()

def link_content():
    p=ROOT/'content/quests/drowned_patrol.tres'; s=p.read_text(encoding='utf-8')
    if 'id="next"' not in s:
        s=s.replace('[sub_resource','[ext_resource type="Resource" path="res://content/quests/unseen_hand.tres" id="next"]\n[sub_resource',1)
        s+='next_quest = ExtResource("next")\n'
    p.write_text(s,encoding='utf-8')
    p=ROOT/'content/catalog.tres';s=p.read_text(encoding='utf-8')
    for name in ['soldiers_pauldrons','black_reliquary','veyne_letter']:
        if f'id="{name}"' not in s:
            s=s.replace('[resource]',f'[ext_resource type="Resource" path="res://content/items/{name}.tres" id="{name}"]\n[resource]',1)
            s=s.replace('ExtResource("captains_breastplate")',f'ExtResource("{name}"), ExtResource("captains_breastplate")',1)
    p.write_text(s,encoding='utf-8')
    p=ROOT/'content/loot/marsh_wildlife.tres';s=p.read_text(encoding='utf-8')
    if 'id="tonic"' not in s:
        s=s.replace('[sub_resource', '[ext_resource type="Resource" path="res://content/items/tonic.tres" id="tonic"]\n[sub_resource',1)
        s=s.replace('[resource]','[sub_resource type="Resource" id="tonic"]\nscript = ExtResource("entry")\nitem = ExtResource("tonic")\nchance = 0.02\n[resource]',1)
        s=s.replace('([SubResource("marshscale_tunic")','([SubResource("tonic"),SubResource("marshscale_tunic")')
    p.write_text(s,encoding='utf-8')

def overlay():
    p=ROOT/'scenes/world/hollowmere.tscn';s=p.read_text(encoding='utf-8')
    # Keep the existing patrol's stable ID, clear of the new west gate tower.
    s=s.replace('position = Vector3(-121.000, 0.100, -112.000)', 'position = Vector3(-125.000, 0.100, -112.000)')
    p.write_text(s,encoding='utf-8')
    if 'id="darkmere_overlay"' in s: return
    s=s.replace('[sub_resource type="NavigationMesh"','[ext_resource type="PackedScene" path="res://scenes/world/darkmere_overlay.tscn" id="darkmere_overlay"]\n[ext_resource type="Script" path="res://src/world/hold_exterior.gd" id="hold_art"]\n[ext_resource type="Script" path="res://src/world/mark_investigation.gd" id="investigation"]\n[ext_resource type="PackedScene" path="res://scenes/world/investigation_sites.tscn" id="sites"]\n[sub_resource type="NavigationMesh"',1)
    s+='''
[node name="DarkmereApproach" parent="." instance=ExtResource("darkmere_overlay")]
[node name="DarkmereKeep" type="Node3D" parent="NavigationRegion/Scenery"]
position = Vector3(-111,0,-114)
script = ExtResource("hold_art")
[node name="MarkInvestigation" parent="." instance=ExtResource("sites")]
[node name="darkmere" type="Marker3D" parent="Arrivals"]
position = Vector3(-111,0.1,-108)
[node name="DarkmereHold" type="Node3D" parent="Portals"]
position = Vector3(-111,0,-117)
script = ExtResource("crypt_portal")
display_name = "Enter Darkmere Hold"
destination = &"darkmere_halls"
required_quest = &"darkmere"
locked_message = "Bring Veyne's orders to Elric before entering the keep."
appearance = "woods"
[node name="DarkmereHold" type="Marker3D" parent="PointsOfInterest"]
position = Vector3(-111,0,-114)
metadata/display_name = "Darkmere Hold"
'''
    p.write_text(s,encoding='utf-8')

def scenes():
    write('scenes/world/darkmere_overlay.tscn','''[gd_scene format=3]
[node name="DarkmereApproach" type="Node3D"]''')
    s='''[gd_scene format=3]
[ext_resource type="Script" path="res://src/world/mark_investigation.gd" id="controller"]
[ext_resource type="Script" path="res://src/world/necromantic_mark.gd" id="mark"]
[ext_resource type="Resource" path="res://content/enemies/zombie.tres" id="zombie"]
[ext_resource type="Resource" path="res://content/enemies/skeletal_archer.tres" id="archer"]
[ext_resource type="Resource" path="res://content/enemies/zombie_brute.tres" id="brute"]
[ext_resource type="Resource" path="res://content/items/veyne_letter.tres" id="note"]
[node name="MarkInvestigation" type="Node3D"]
script = ExtResource("controller")
zombie = ExtResource("zombie")
archer = ExtResource("archer")
brute = ExtResource("brute")
note = ExtResource("note")
'''
    for id,x,z in [('graves',-44,-81),('tollhouse',94,-34),('beacon',109,-104)]:
        s+=f'[node name="{id}" type="Node3D" parent="."]\nposition = Vector3({x},0.08,{z})\nscript = ExtResource("mark")\nsite_id = &"{id}"\n'
    write('scenes/world/investigation_sites.tscn',s)
    for upper in [False,True]:
        ident='darkmere_sanctum' if upper else 'darkmere_halls'
        s='''[gd_scene format=3]
[ext_resource type="Script" path="res://src/world/region.gd" id="region"]
[ext_resource type="Script" path="res://src/world/crypt_chamber.gd" id="room"]
[ext_resource type="Script" path="res://src/world/hold_dressing.gd" id="dressing"]
[ext_resource type="Script" path="res://src/world/region_portal.gd" id="portal"]
[ext_resource type="Script" path="res://src/world/encounter.gd" id="encounter"]
[ext_resource type="Script" path="res://src/world/enemy_spawn.gd" id="spawn"]
'''
        for name in ['zombie','skeletal_archer','marsh_widow','malrec']:
            s+=f'[ext_resource type="Resource" path="res://content/enemies/{name}.tres" id="{name}"]\n'
        s+='''[ext_resource type="Script" path="res://src/world/malrec_encounter.gd" id="boss_controller"]
[ext_resource type="Resource" path="res://content/encounters/malrec.tres" id="boss_kit"]
[sub_resource type="NavigationMesh" id="nav"]
geometry_parsed_geometry_type = 1
geometry_collision_mask = 1
cell_size = 0.3
cell_height = 0.1
agent_radius = 0.6
agent_height = 2.0
agent_max_climb = 0.5
'''
        s+=f'''[node name="Darkmere" type="Node3D"]
script = ExtResource("region")
region_id = &"{ident}"
display_name = "Darkmere Hold · {'The Upper Chamber' if upper else 'The Lower Halls'}"
interior = true
recovery_region = &"hollowmere"
hub_name = "Lanternwatch Camp"
music_track = &"chapel_crypts"
interior_ambient = {0.34 if upper else 0.20}
interior_sun = {0.20 if upper else 0.10}
map_bounds = Rect2({-20 if upper else -24},{-18 if upper else -35},{40 if upper else 48},{36 if upper else 70})
'''
        if upper: s+='encounter_music_track = &"vanes_den"\nencounter_music_owner = NodePath("MalrecEncounter")\n'
        s+='[node name="NavigationRegion" type="NavigationRegion3D" parent="."]\nnavigation_mesh = SubResource("nav")\n[node name="Scenery" type="Node3D" parent="NavigationRegion"]\n'
        if upper:
            s+='[node name="GreatChamber" type="Node3D" parent="NavigationRegion/Scenery"]\nscript = ExtResource("room")\nextent = Vector2(36,32)\nsouth_opening = 4.0\ndecor = "sanctum"\n'
        else:
            rooms=[('Hall',0,0,10,64,'north_opening = 4.0\nsouth_opening = 4.0\nwest_openings = PackedVector2Array(12,4.2,-23,4.2)\neast_openings = PackedVector2Array(-8,4.2)'),('Barracks',-12,12,14,14,'east_openings = PackedVector2Array(0,4.2)'),('Store',13,-8,16,16,'west_openings = PackedVector2Array(0,4.2)'),('Guardroom',-12,-23,14,14,'east_openings = PackedVector2Array(0,4.2)')]
            for name,x,z,w,h,doors in rooms:
                s+=f'[node name="{name}" type="Node3D" parent="NavigationRegion/Scenery"]\nposition = Vector3({x},0,{z})\nscript = ExtResource("room")\nextent = Vector2({w},{h})\nlit = false\nfurnishings = false\n{doors}\n'
        s+=f'[node name="Furnishings" type="Node3D" parent="NavigationRegion/Scenery"]\nscript = ExtResource("dressing")\nupper = {str(upper).lower()}\n'
        s+='[node name="Actors" type="Node3D" parent="."]\n[node name="NPCs" type="Node3D" parent="."]\n[node name="Arrivals" type="Node3D" parent="."]\n'
        s+=f'[node name="PlayerSpawn" type="Marker3D" parent="."]\nposition = Vector3(0,0.1,{13 if upper else 29})\n'
        s+='[node name="upstairs" type="Marker3D" parent="Arrivals"]\nposition = Vector3(0,0.1,-27)\n[node name="Portals" type="Node3D" parent="."]\n'
        s+=f'''[node name="Exit" type="Node3D" parent="Portals"]
position = Vector3(0,0,{14.5 if upper else 30.5})
script = ExtResource("portal")
display_name = "{'Return to the lower halls' if upper else 'Return to Hollowmere'}"
destination = &"{'darkmere_halls' if upper else 'hollowmere'}"
arrival = &"{'upstairs' if upper else 'darkmere'}"
appearance = "stairs"
'''
        if not upper:
            s+='[node name="UpperFloor" type="Node3D" parent="Portals"]\nposition = Vector3(0,0,-29)\nscript = ExtResource("portal")\ndisplay_name = "Ascend to the upper chamber"\ndestination = &"darkmere_sanctum"\nappearance = "stairs"\n'
        s+='[node name="Encounters" type="Node3D" parent="."]\n'
        groups=[('malrec',[('malrec',0,-6)])] if upper else [
            ('gate',[('zombie',0,19),('zombie',2,15),('marsh_widow',1,12)]),
            ('barracks',[('zombie',-9,10),('zombie',-14,9),('skeletal_archer',-14,16)]),
            ('passage',[('zombie',1,3),('marsh_widow',-1,-3),('skeletal_archer',1,-9)]),
            ('store',[('zombie',9,-9),('marsh_widow',15,-12),('marsh_widow',16,-5),('skeletal_archer',12,-3)]),
            ('guardroom',[('zombie',-10,-22),('zombie',-15,-24),('skeletal_archer',-13,-18)]),
            ('stairs',[('zombie',0,-21),('marsh_widow',2,-25)])]
        for group,enemies in groups:
            s+=f'[node name="{group}" type="Node3D" parent="Encounters"]\nscript = ExtResource("encounter")\nencounter_id = &"{group if upper else "darkmere_"+group}"\n'
            for i,(kind,x,z) in enumerate(enemies):
                id='darkmere_malrec' if upper else f'darkmere_{group}_{i}'
                s+=f'[node name="Enemy{i}" type="Marker3D" parent="Encounters/{group}"]\nposition = Vector3({x},0.1,{z})\nscript = ExtResource("spawn")\nspawn_id = &"{id}"\ndefinition = ExtResource("{kind}")\n'
        if upper:
            s+='[node name="MalrecEncounter" type="Node3D" parent="."]\nscript = ExtResource("boss_controller")\ndefinition = ExtResource("boss_kit")\n'
            for group,points in [('TeleportPoints',[(-12,-8),(12,-8),(-12,9),(12,9)]),('CultistPoints',[(-10,-9),(10,-9),(-10,8),(10,8)])]:
                s+=f'[node name="{group}" type="Node3D" parent="MalrecEncounter"]\n'
                for i,(x,z) in enumerate(points): s+=f'[node name="Point{i}" type="Marker3D" parent="MalrecEncounter/{group}"]\nposition = Vector3({x},0.1,{z})\n'
        write(f'scenes/world/{ident}.tscn',s)

if __name__=='__main__': author()
