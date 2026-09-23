"""Offline authoring source for Hollowmere's native, editor-editable resources/scene.
Run from the project root. Runtime never imports Python or generates encounters.
"""
from pathlib import Path
import math
import random
import struct

ROOT = Path(__file__).resolve().parents[1]
atlas_path = ROOT/'assets/ui/marsh_gear_atlas.png'
atlas_cell = struct.unpack('>II',atlas_path.read_bytes()[16:24])[0]/4 if atlas_path.exists() else 313.5
def write(path, data):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(data, encoding='utf-8')

# ID, name, slot, tier, chance, stats, appearance, description
ITEMS = [
('marshscale_tunic','Marshscale Tunic','body','white',.025,{'armor_bonus':3},'leather','Overlapping scales shed the black water of the fen.'),
('bogwalker_boots','Bogwalker Boots','boots','white',.025,{'armor_bonus':2},'leather','Heavy soles for the uncertain ground beyond the causeway.'),
('rotcap_cowl','Rotcap Cowl','head','white',.025,{'armor_bonus':2},'hood','Waxed cloth keeps the cold marsh mist from your neck.'),
('swampgrip_mitts','Swampgrip Mitts','gloves','white',.025,{'armor_bonus':2},'leather','Hide palms roughened for wet hilts and slippery ropes.'),
('mud_stained_sash','Mud-Stained Sash','belt','white',.025,{'armor_bonus':2},'plain','The mud has outlasted every attempt to wash it clean.'),
('bogwood_shield','Bogwood Shield','shield','white',.02,{'armor_bonus':3},'oak','Water-darkened timber bound with weathered iron.'),
('marsh_cleaver','Marsh Cleaver','weapon','white',.02,{'damage_bonus':7,'swing_seconds':.9},'cleaver','A broad, notched edge made to cut more than reeds.'),
('gloomhide_vest','Gloomhide Vest','body','green',.015,{'armor_bonus':5,'vitality_bonus':5},'leather','Layered river-beast hide sewn with bronze wire.'),
('marshrunner_boots','Marshrunner Boots','boots','green',.015,{'armor_bonus':2,'movement_bonus':5},'reinforced','Light enough to outrun the things beneath the lily pads.'),
('marshguard_crown','Marshguard Crown','head','green',.015,{'armor_bonus':3,'strength_bonus':1,'vitality_bonus':5},'helmet','A tarnished circlet from the wardens of the old embankment.'),
('marshwarden_sash','Marshwarden Sash','belt','green',.015,{'armor_bonus':2,'strength_bonus':1},'reinforced','The keeper clasp still bears a faded reed sigil.'),
('fenwarden_charm','Fenwarden Charm','amulet','green',.015,{'vitality_bonus':10},'amulet','Amber holds a single reed seed, dry after all these years.'),
('marshwarden_band','Marshwarden Band','ring','green',.015,{'strength_bonus':1},'plain','A heavy band of bronze and dark fenstone.'),
('bogiron_greatblade','Bogiron Greatblade','weapon','green',.01,{'damage_bonus':20,'swing_seconds':1.9,'crit_rating':2,'two_handed':True},'greatblade','A patient, merciless edge forged from iron pulled out of the mire.'),
]
for index,(id,name,slot,tier,chance,stats,appearance,description) in enumerate(ITEMS):
    fields = '\n'.join(f'{key} = {str(value).lower()}' for key,value in stats.items())
    write(f'content/items/{id}.tres',f'''[gd_resource type="Resource" script_class="ItemDefinition" load_steps=4 format=3]
[ext_resource type="Script" path="res://src/data/item_definition.gd" id="script"]
[ext_resource type="Texture2D" path="res://assets/ui/marsh_gear_atlas.png" id="atlas"]
[sub_resource type="AtlasTexture" id="icon"]
atlas = ExtResource("atlas")
region = Rect2({index%4*atlas_cell}, {index//4*atlas_cell}, {atlas_cell}, {atlas_cell})
filter_clip = true
[resource]
script = ExtResource("script")
id = &"{id}"
display_name = "{name}"
description = "{description}"
slot = "{slot}"
tier = "{tier}"
appearance = "{appearance}"
icon = SubResource("icon")
price = {45 if tier=='green' else 20}
sell_price = {9 if tier=='green' else 4}
tint = Color(0.29, 0.39, 0.30, 1)
{fields}
''')

catalog = (ROOT/'content/catalog.tres').read_text(encoding='utf-8')
if 'id="marshscale_tunic"' not in catalog:
    refs = ''.join(f'[ext_resource type="Resource" path="res://content/items/{i[0]}.tres" id="{i[0]}"]\n' for i in ITEMS)
    catalog = catalog.replace('[resource]',refs+'[resource]').replace('load_steps=29','load_steps=43')
    catalog = catalog.replace('ExtResource("bloodclaw")])','ExtResource("bloodclaw"), '+', '.join(f'ExtResource("{i[0]}")' for i in ITEMS)+'])')
    write('content/catalog.tres',catalog)

# Expedition stock is authored separately from wildlife drops.
VENDOR_ITEMS = [
('wyrmhide_grips','Wyrmhide Grips','gloves',125,{'armor_bonus':3,'strength_bonus':1,'crit_rating':1},'reinforced','Scaled hide and steel keep a sure grip in the rain.'),
('emerald_band','Emerald Band','ring',125,{'crit_rating':1,'strength_bonus':1},'plain','A clear green stone set in a heavy, timeworn band.'),
('wyrmsteel_shoulders','Wyrmsteel Shoulders','shoulders',150,{'armor_bonus':4,'vitality_bonus':10},'reinforced','Overlapping plates carry the weight of the expedition.'),
('oakheart_guard','Oakheart Guard','shield',150,{'armor_bonus':5,'vitality_bonus':10},'oak','Living heartwood held fast by weathered bronze.'),
('wyrmfang','Wyrmfang','weapon',225,{'damage_bonus':23,'swing_seconds':2.0,'strength_bonus':2,'vitality_bonus':10,'two_handed':True},'polearm','A hooked blade on a long haft, made to keep the mire at bay.'),
]
vendor_atlas = ROOT/'assets/ui/rowan_gear_atlas.png'
vendor_cell = struct.unpack('>II',vendor_atlas.read_bytes()[16:24])[0]/3
for index,(id,name,slot,price,stats,appearance,description) in enumerate(VENDOR_ITEMS):
    fields='\n'.join(f'{key} = {str(value).lower()}' for key,value in stats.items())
    write(f'content/items/{id}.tres',f'''[gd_resource type="Resource" script_class="ItemDefinition" load_steps=4 format=3]
[ext_resource type="Script" path="res://src/data/item_definition.gd" id="script"]
[ext_resource type="Texture2D" path="res://assets/ui/rowan_gear_atlas.png" id="atlas"]
[sub_resource type="AtlasTexture" id="icon"]
atlas = ExtResource("atlas")
region = Rect2({index%3*vendor_cell}, {index//3*vendor_cell}, {vendor_cell}, {vendor_cell})
filter_clip = true
[resource]
script = ExtResource("script")
id = &"{id}"
display_name = "{name}"
description = "{description}"
slot = "{slot}"
tier = "green"
appearance = "{appearance}"
icon = SubResource("icon")
price = {price}
sell_price = {min(16,price//8)}
tint = Color(0.28, 0.39, 0.31, 1)
{fields}
''')
catalog=(ROOT/'content/catalog.tres').read_text(encoding='utf-8')
if 'id="wyrmhide_grips"' not in catalog:
    refs=''.join(f'[ext_resource type="Resource" path="res://content/items/{i[0]}.tres" id="{i[0]}"]\n' for i in VENDOR_ITEMS)
    catalog=catalog.replace('[resource]',refs+'[resource]').replace('load_steps=43','load_steps=48')
    catalog=catalog.replace('ExtResource("bogiron_greatblade")])','ExtResource("bogiron_greatblade"), '+', '.join(f'ExtResource("{i[0]}")' for i in VENDOR_ITEMS)+'])')
    write('content/catalog.tres',catalog)

loot = '[gd_resource type="Resource" script_class="LootTable" format=3]\n'
loot += '[ext_resource type="Script" path="res://src/data/loot_table.gd" id="table"]\n[ext_resource type="Script" path="res://src/data/loot_entry.gd" id="entry"]\n'
loot += ''.join(f'[ext_resource type="Resource" path="res://content/items/{i[0]}.tres" id="{i[0]}"]\n' for i in ITEMS)
for i in ITEMS:
    loot += f'[sub_resource type="Resource" id="{i[0]}"]\nscript = ExtResource("entry")\nitem = ExtResource("{i[0]}")\nchance = {i[4]}\n'
loot += '[resource]\nscript = ExtResource("table")\ngold_weights = PackedFloat32Array(70, 0, 0, 12, 10, 8)\nentries = Array[ExtResource("entry")](['+', '.join(f'SubResource("{i[0]}")' for i in ITEMS)+'])\n'
write('content/loot/marsh_wildlife.tres',loot)
for id,name,hp,damage,chance,exp,speed,scale in [('crocodile','Crocodile',100,20,.7,2,2.8,1),('marsh_widow','Marsh Widow',80,17,.7,2,3.5,.85),('broodqueen','Marsh Broodqueen',150,25,.9,3,2.75,1.35)]:
    poison = 'poison_damage = 1.0\npoison_seconds = 3.0\n' if id=='marsh_widow' else ''
    write(f'content/attacks/{id}.tres',f'''[gd_resource type="Resource" script_class="AttackDefinition" format=3]
[ext_resource type="Script" path="res://src/data/attack_definition.gd" id="script"]
[resource]
script = ExtResource("script")
id = &"{id}_bite"
damage = {damage}.0
reach = {2.3 if id=='crocodile' else 2.1}
windup = {0.5 if id=='crocodile' else 0.38}
cooldown = {1.5 if id=='crocodile' else 1.35}
arc_degrees = 85.0
{poison}''')
    web = 'web_cooldown = 11.0\nweb_range = 10.0\nweb_root_seconds = 2.0\n' if id=='broodqueen' else ''
    write(f'content/enemies/{id}.tres',f'''[gd_resource type="Resource" script_class="EnemyDefinition" format=3]
[ext_resource type="Script" path="res://src/data/enemy_definition.gd" id="script"]
[ext_resource type="Resource" path="res://content/attacks/{id}.tres" id="attack"]
[ext_resource type="Resource" path="res://content/loot/marsh_wildlife.tres" id="loot"]
[resource]
script = ExtResource("script")
id = &"{id}"
display_name = "{name}"
appearance = "{id}"
audio_profile = "reptile"{'' if id=='crocodile' else '\n'}
max_health = {hp}.0
hit_chance = {chance}
experience = {exp}
move_speed = {speed}
visual_scale = {scale}
collision_radius = {0.65 if id!='marsh_widow' else 0.45}
collision_height = {1.2 if id=='broodqueen' else 0.9}
aggro_radius = 10.0
leash_radius = 28.0
voice_pitch = {0.75 if id=='crocodile' else 1.3}
attack = ExtResource("attack")
loot_table = ExtResource("loot")
{web}'''.replace('audio_profile = "reptile"','audio_profile = "spider"' if id!='crocodile' else 'audio_profile = "reptile"'))

NPCS = [
('oswin','Master Oswin','Veteran instructor','trainer','A habit can be unlearned. For one hundred gold, we can begin your training anew.','npc'),
('rowan','Quartermaster Rowan','Expedition supplies','vendor','Keep your steel dry and your boots tied. The mire swallows anything you cannot carry.','npc'),
('maelin','Sister Maelin','Keeper of the lantern ward','healer','Sit by the light. There are fevers in this water that steel will never cure.','npc'),
('tamsin','Captain Tamsin','Expedition instructor','trainer','The marsh punishes old habits. One hundred gold buys time at the practice ring and a fresh beginning.','npc'),
]
for id,name,title,service,greeting,appearance in NPCS:
    refs=''
    stock=''
    if service=='vendor':
        ids=['tonic','greater_tonic','guardian_amulet']+[i[0] for i in VENDOR_ITEMS]
        refs='[ext_resource type="Script" path="res://src/data/item_definition.gd" id="item"]\n'+''.join(f'[ext_resource type="Resource" path="res://content/items/{i}.tres" id="{i}"]\n' for i in ids)
        stock='stock = Array[ExtResource("item")](['+', '.join(f'ExtResource("{i}")' for i in ids)+'])\n'
    write(f'content/npcs/{id}.tres',f'''[gd_resource type="Resource" script_class="NpcDefinition" format=3]
[ext_resource type="Script" path="res://src/data/npc_definition.gd" id="script"]
{refs}[resource]
script = ExtResource("script")
id = &"{id}"
display_name = "{name}"
title = "{title}"
service = "{service}"
greeting = "{greeting}"
appearance = "{appearance}"
tint = Color(0.34, 0.43, 0.36, 1)
{stock}''')

roads = [
('OldCauseway',[(-105,94),(-80,65),(-60,54),(-60,30),(-38,8),(-18,-24),(6,-45),(40,-63),(76,-91),(114,-110)],5.5),
('WidowTrack',[(-60,30),(-101,28),(-112,-6),(-100,-40),(-82,-70),(-106,-102)],3.7),
('ReedbankLoop',[(-38,8),(0,28),(40,38),(78,23),(106,-6),(98,-42),(76,-91)],4.2),
('DrownedPilgrimRoad',[(-80,65),(-45,85),(0,95),(48,90),(88,71),(78,23)],4.2),
('GravekeeperPath',[(-82,-70),(-41,-83),(6,-45)],3.6),
('SluicePath',[(0,28),(10,-7),(-18,-24)],3.5),
]
rng = random.Random(72941)
pond_specs=[('CausewayFlood',-60,43,16,8),('WestMere',-73,-9,23,29),('Reedwater',-23,59,24,15),('DrownedFields',29,65,33,17),('Blackwater',60,-5,32,19),('NorthMere',15,-84,31,22),('WidowPool',-113,-76,18,12),('EasternFlood',113,97,25,23),('SouthPool',-4,113,28,9),('CampShore',-120,60,16,13),('Sluice',10,5,16,7)]
ponds=[]
for name,x,z,rx,rz in pond_specs:
    polygon=[]
    for i in range(16):
        a=i*math.tau/16
        r=rng.uniform(.87,1.08)
        polygon.append((round(x+math.cos(a)*rx*r,2),round(z+math.sin(a)*rz*r,2)))
    ponds.append((name,polygon))
def inside(p,polygon):
    x,z=p; result=False
    for i,(ax,az) in enumerate(polygon):
        bx,bz=polygon[i-1]
        if (az>z)!=(bz>z) and x<(bx-ax)*(z-az)/(bz-az)+ax: result=not result
    return result
def segment_distance(p,a,b):
    dx,dz=b[0]-a[0],b[1]-a[1]
    t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dz)/(dx*dx+dz*dz)))
    return math.hypot(p[0]-a[0]-dx*t,p[1]-a[1]-dz*t)
def road_distance(p): return min(segment_distance(p,a,b) for _,points,_ in roads for a,b in zip(points,points[1:]))
def water(p): return any(inside(p,poly) for _,poly in ponds)

scene = ['[gd_scene format=3]']
scripts={'region':'world/region','ground':'world/marsh_ground','marsh':'world/marsh_prop','water':'world/marsh_water','prop':'world/world_prop','road':'world/road','encounter':'world/encounter','spawn':'world/enemy_spawn','npc':'interaction/npc','chest':'world/treasure_chest'}
scripts['ambience']='presentation/region_ambience'
scene += [f'[ext_resource type="Script" path="res://src/{path}.gd" id="{id}"]' for id,path in scripts.items()]
scene += [f'[ext_resource type="Resource" path="res://content/enemies/{id}.tres" id="{id}"]' for id in ['crocodile','marsh_widow','broodqueen']]
scene += [f'[ext_resource type="Resource" path="res://content/npcs/{id}.tres" id="{id}"]' for id in ['elric','rowan','maelin','tamsin']]
scene += ['''[sub_resource type="NavigationMesh" id="navmesh"]
geometry_parsed_geometry_type = 1
geometry_collision_mask = 1
cell_size = 0.4
cell_height = 0.25
agent_height = 2.0
agent_radius = 0.8
agent_max_climb = 0.5
agent_max_slope = 45.0
filter_baking_aabb = AABB(-144, -1, -128, 288, 3.5, 256)
[node name="Hollowmere" type="Node3D"]
script = ExtResource("region")
display_name = "The Hollowmere Marshes"
region_id = &"hollowmere"
recovery_region = &"hollowmere"
hub_name = "Lanternwatch Camp"
map_bounds = Rect2(-144, -128, 288, 256)
music_track = &"hollowmere"
local_music_track = &"hollowmere_camp"
local_music_bounds = Rect2(-128, 76, 46, 39)
outdoor_ambient = 0.52
outdoor_sun = 0.38
fog_color = Color(0.16, 0.23, 0.22, 1)
fog_density = 0.009
[node name="NavigationRegion" type="NavigationRegion3D" parent="."]
navigation_mesh = SubResource("navmesh")
[node name="Terrain" type="Node3D" parent="NavigationRegion"]
script = ExtResource("ground")
[node name="Scenery" type="Node3D" parent="NavigationRegion"]
''']
def node(name,type,parent,props=''):
    scene.append(f'[node name="{name}" type="{type}" parent="{parent}"]\n{props}')
def vector(x,z,y=0): return f'Vector3({x:.3f}, {y:.3f}, {z:.3f})'
counter=0
occupied=[]
def prop(kind,x,z,rotation=0,scale=1,**fields):
    global counter
    counter+=1
    script='prop' if kind in ['tent','fire','banner','crate','ruin','rock','house','tower','fence','well'] else 'marsh'
    extra='\n'.join(f'{k} = {v}' for k,v in fields.items())
    node(f'{kind}_{counter}','Node3D','NavigationRegion/Scenery',f'position = {vector(x,z)}\nrotation = Vector3(0, {rotation}, 0)\nscale = Vector3({scale}, {scale}, {scale})\nscript = ExtResource("{script}")\nkind = "{kind}"\nvariation = {counter}\n{extra}')
    if kind not in ['reeds','lamp','web_nest']: occupied.append((x,z))
for name,poly in ponds:
    packed=', '.join(f'{x}, {z}' for x,z in poly)
    crossings='\ncrossings = Array[Rect2]([Rect2(-62.3, 30, 4.6, 26)])' if name=='CausewayFlood' else ('\ncrossings = Array[Rect2]([Rect2(7.7, -5, 4.6, 20)])' if name=='Sluice' else '')
    node(name,'Node3D','NavigationRegion',f'script = ExtResource("water")\nshore = PackedVector2Array({packed}){crossings}')
for name,points,width in roads:
    packed=', '.join(f'{x}, 0, {z}' for x,z in points)
    node(name,'MeshInstance3D','NavigationRegion',f'script = ExtResource("road")\npoints = PackedVector3Array({packed})\nwidth = {width}\ntint = Color(0.34, 0.35, 0.27, 1)')
node('CampSquare','MeshInstance3D','NavigationRegion','script = ExtResource("road")\npoints = PackedVector3Array(-120,0,95,-89,0,95)\nwidth = 24.0\ntint = Color(0.34,0.35,0.30,1)')
prop('bridge',-60,43,length=24.0)
prop('bridge',10,5,length=19.0)
# Expedition camp: canvas quarters, cooking fire, supplies, ward, practice ring.
for x,z,angle in [(-118,88,0),(-105,82,0),(-91,88,-.5),(-119,106,math.pi),(-93,106,math.pi)]: prop('tent',x,z,angle,1.45)
prop('fire',-106,98,scale=.85)
prop('well',-116,98,scale=.8)
prop('banner',-102,87)
for x,z in [(-123,91),(-123,93),(-122,108),(-90,109),(-88,107)]: prop('crate',x,z)
prop('supplies',-113,85)
prop('supplies',-95,103)
prop('target',-113,110)
prop('target',-110,110)
for x in [-124,-121,-118,-96,-93,-90,-87]: prop('palisade',x,114)
for x in [-124,-121,-118,-114,-110,-100,-96,-92,-88]: prop('palisade',x,75)
for x,z in [(-121,81),(-90,81),(-119,111),(-92,111),(-106,92),(-87,98)]: prop('lamp',x,z)
# Landmarks, environmental storytelling, and caches with no quest requirements.
landmarks=[('Siltwater Landing',-99,30),('The Sunken Chapel',42,38),('Widows Weald',-103,-38),('Pilgrim Graves',-44,-85),('Broken Sluice',9,-10),('The Drowned Tollhouse',96,-39),('Old Beacon',113,-108)]
prop('ferry',-98,36,1.2)
for x in [-104,-100,-96]: prop('crate',x,33)
prop('shrine',42,38)
for x,z in [(35,32),(47,34),(36,44),(49,42)]: prop('ruin',x,z,.3)
for x,z in [(-106,-45),(-98,-37),(-94,-46)]: prop('web_nest',x,z)
for x in [-52,-48,-44,-40,-36]:
    for z in [-90,-86]: prop('grave',x,z,rng.uniform(-.3,.3))
prop('ruin',4,-13)
prop('ruin',16,-12)
prop('house',104,-40,scale=.85)
prop('ruin',95,-46)
prop('tower',119,-110,scale=.75)
prop('fire',113,-111)
for _,x,z in landmarks: prop('lamp',x-3,z+4)
for _,points,_ in roads:
    for x,z in points[1::2]:
        if not water((x+4,z)): prop('lamp',x+4,z)
# Enemy groups: deliberately outside camp and its safe approach, stable authored IDs.
groups=[('crocodile',-83,47),('crocodile',-93,9),('crocodile',-50,16),('crocodile',-22,34),('crocodile',25,42),('crocodile',67,28),('crocodile',105,15),('crocodile',103,64),('crocodile',48,91),('crocodile',-5,95),('crocodile',-20,-40),('crocodile',47,-44),('crocodile',89,-60),('crocodile',-40,-101),('crocodile',-128,-44),('crocodile',107,-104),('broodqueen',-104,-36),('broodqueen',-89,-61),('broodqueen',-46,-74),('broodqueen',-27,8),('broodqueen',10,-32),('broodqueen',82,5),('broodqueen',91,-36),('broodqueen',69,71),('broodqueen',35,105),('broodqueen',-68,4),('broodqueen',53,-95),('broodqueen',-102,-104)]
# Preserve save IDs while moving selected packs into dry shoreline clearings.
for index,x,z in [(1,-124,10),(3,-38,36),(5,63,46),(6,126,8),(8,60,108),(10,-36,-42),(12,120,-64),(17,-66,-60),(19,-18,7),(20,31,-31),(23,65,87),(26,70,-113)]:
    groups[index]=(groups[index][0],x,z)
groups += [('crocodile',-122,42),('broodqueen',-124,-110),('crocodile',124,-20),('broodqueen',-4,-55)]
spawn_points=[]
def dry_point(x,z):
    if not water((x,z)): return x,z
    for radius in range(3,40,2):
        for i in range(16):
            p=(x+math.cos(i*math.tau/16)*radius,z+math.sin(i*math.tau/16)*radius)
            if not water(p) and abs(p[0])<137 and abs(p[1])<121: return p
    raise ValueError('No dry spawn')
node('Ambience','Node','.', 'script = ExtResource("ambience")')
node('Actors','Node3D','.')
node('PlayerSpawn','Marker3D','.',f'position = {vector(-104,94,.1)}')
node('Encounters','Node3D','.')
for n,(kind,x,z) in enumerate(groups):
    x,z=dry_point(x,z)
    members=[(kind,x,z)]
    if kind=='broodqueen':
        prop('web_nest',x+3,z+1)
        for dx,dz in [(-3,-2),(3,-2),(0,3)]:
            px,pz=dry_point(x+dx,z+dz); members.append(('marsh_widow',px,pz))
    elif n%3==0:
        px,pz=dry_point(x+3,z+3); members.append(('crocodile',px,pz))
    node(f'marsh_{n:02}','Node3D','Encounters',f'script = ExtResource("encounter")\nencounter_id = &"hollowmere_{n:02}"')
    for j,(enemy,px,pz) in enumerate(members):
        spawn_points.append((px,pz))
        node(f'Enemy{j}','Marker3D',f'Encounters/marsh_{n:02}',f'position = {vector(px,pz,.1)}\nscript = ExtResource("spawn")\nspawn_id = &"hollowmere_{n:02}_{j}"\ndefinition = ExtResource("{enemy}")')
node('NPCs','Node3D','.')
for id,x,z in [('elric',-103,89),('rowan',-115,90),('maelin',-93,98),('tamsin',-114,106)]:
    node(id,'Node3D','NPCs',f'position = {vector(x,z,.1)}\nscript = ExtResource("npc")\ndefinition = ExtResource("{id}")')
node('PointsOfInterest','Node3D','.')
node('LanternwatchCamp','Marker3D','PointsOfInterest',f'position = {vector(-104,94)}\nmetadata/display_name = "Lanternwatch Camp"')
for name,x,z in landmarks: node(name.replace(' ',''),'Marker3D','PointsOfInterest',f'position = {vector(x,z)}\nmetadata/display_name = "{name}"')
chests=[(-99,27,12),(44,45,15),(-104,-48,20),(-42,-80,10),(92,-38,18)]
for i,(x,z,gold) in enumerate(chests):
    node(f'Cache{i}','Node3D','.',f'position = {vector(x,z)}\nscript = ExtResource("chest")\nchest_id = "hollowmere_cache_{i}"\ndisplay_name = "weathered strongbox"\ngold = {gold}')
    occupied.append((x,z))
# Irregular groves keep authored roads, NPCs, cache approaches and spawns open.
for i in range(950):
    x,z=rng.uniform(-140,140),rng.uniform(-124,124)
    if -132<x<-77 and 70<z<119: continue
    if water((x,z)) or road_distance((x,z))<4.5: continue
    if any(math.hypot(x-px,z-pz)<4 for px,pz in occupied+spawn_points): continue
    prop('cypress',x,z,rng.random()*math.tau,rng.uniform(.73,1.22))
    if sum(1 for s in scene if 'kind = "cypress"' in s)>=280: break
for _,polygon in ponds:
    for i,(x,z) in enumerate(polygon):
        bridge_clear = not (-64<x<-56 and 27<z<59) and not (6<x<14 and -8<z<18)
        if bridge_clear: prop('reeds',x,z,rng.random()*math.tau,rng.uniform(.7,1.6))
        if bridge_clear and i%4==0 and road_distance((x,z))>5: prop('rock',x,z,scale=rng.uniform(.5,.9))
for i in range(70):
    x,z=rng.uniform(-135,135),rng.uniform(-120,120)
    if -132<x<-77 and 70<z<119 or water((x,z)) or road_distance((x,z))<4: continue
    prop('mushrooms',x,z)
    if i%2==0:
        points=[(x+math.cos(a*math.tau/10)*rng.uniform(1.5,3.5),z+math.sin(a*math.tau/10)*rng.uniform(1.0,2.5)) for a in range(10)]
        packed=', '.join(f'{px:.2f}, {pz:.2f}' for px,pz in points)
        node(f'ShallowPuddle{i}','Node3D','NavigationRegion',f'script = ExtResource("water")\ndeep = false\nshore = PackedVector2Array({packed})')
write('scenes/world/hollowmere.tscn','\n'.join(scene)+'\n')

march=(ROOT/'scenes/world/briar_march.tscn').read_text(encoding='utf-8')
if 'id="oswin"' not in march:
    march=march.replace('[sub_resource type="NavigationMesh"', '[ext_resource type="Resource" path="res://content/npcs/oswin.tres" id="oswin"]\n[sub_resource type="NavigationMesh"',1)
    march += '\n[node name="oswin" type="Node3D" parent="NPCs"]\nposition = Vector3(-29,0.1,29)\nscript = ExtResource("npc")\ndefinition = ExtResource("oswin")\n'
march=march.replace('position = Vector3(-39,0.1,33)','position = Vector3(-29,0.1,29)')
write('scenes/world/briar_march.tscn',march)
print(f'Authored {len(ITEMS)} items, {len(spawn_points)} enemies, {len(chests)} caches and Hollowmere scenery.')
