class_name MarshCreature
extends RefCounted
## Original articulated wildlife, sharing ActorVisual's hit and gait animation.
static func build(actor: ActorVisual) -> void:
	if actor.style == "crocodile": crocodile(actor)
	else: spider(actor)

static func crocodile(actor: ActorVisual) -> void:
	var root := actor.pivot
	var hide := Color("4a5740")
	Geometry.sphere(root,Vector3(0,0.49,0.15),Vector3(1.05,0.7,2.0),hide)
	Geometry.sphere(root,Vector3(0,0.35,-1.03),Vector3(0.80,0.32,1.35),Color("878366"))
	var snout := Node3D.new()
	root.add_child(snout)
	snout.name = "Snout"
	snout.position = Vector3(0,0.56,-0.65)
	Geometry.sphere(snout,Vector3(0,0,-0.55),Vector3(0.76,0.32,1.45),hide)
	for side in [-1,1]:
		Geometry.sphere(root,Vector3(side*0.3,0.76,-0.72),Vector3(0.20,0.18,0.2),hide.lightened(0.1))
		Geometry.sphere(root,Vector3(side*0.32,0.79,-0.79),Vector3(0.10,0.07,0.09),Color("e9bf52"))
		for i in range(7):
			Geometry.cylinder(snout,Vector3(side*(0.23+i*0.012),-0.15,-0.99+i*0.16),0.045,0.14,Color("d1c79f"),0,4)
		for z in [-0.43,0.72]:
			var leg := Node3D.new()
			root.add_child(leg)
			leg.position = Vector3(side*0.40,0.43,z)
			Geometry.beam(leg,Vector3.ZERO,Vector3(side*0.35,-0.17,0.12),0.23,hide)
			Geometry.beam(leg,Vector3(side*0.35,-0.17,0.12),Vector3(side*0.50,-0.32,-0.12),0.14,hide)
			for claw in range(3):
				Geometry.beam(leg,Vector3(side*0.50+claw*0.07,-0.32,-0.1),Vector3(side*0.50+claw*0.07,-0.35,-0.32),0.045,Color("c8c2a5"))
			actor.legs.append(leg)
	for i in range(6):
		Geometry.sphere(root,Vector3(sin(i*0.5)*0.18,0.35-i*0.045,1.0+i*0.35),Vector3(0.65-i*0.09,0.43-i*0.057,0.70),hide.darkened(i*0.035))
	for z in range(7):
		for x in [-0.23,0.0,0.23]:
			Geometry.cylinder(root,Vector3(x,0.85,z*0.23-0.5),0.105,0.22,Color("2e3c30"),0,4)

static func spider(actor: ActorVisual) -> void:
	var root := actor.pivot
	var queen := actor.style == "broodqueen"
	var shell := Color("42363e") if queen else Color("292e35")
	var marks := Color("b18b60") if queen else Color("823a44")
	Geometry.sphere(root,Vector3(0,0.68,0.52),Vector3(1.25,0.95,1.55),shell)
	Geometry.sphere(root,Vector3(0,0.58,-0.40),Vector3(0.85,0.70,0.90),shell.lightened(0.06))
	for side in [-1,1]:
		for i in range(4):
			var leg := Node3D.new()
			root.add_child(leg)
			leg.position = Vector3(side*0.3,0.60,i*0.25-0.5)
			var knee := Vector3(side*(1.0+sin(i*0.8)*0.25),0.42, (i-1.5)*0.43)
			var foot := Vector3(side*(1.45+sin(i)*0.2),-0.55,(i-1.5)*0.80)
			Geometry.beam(leg,Vector3.ZERO,knee,0.14,shell)
			Geometry.sphere(leg,knee,Vector3.ONE*0.2,marks.darkened(0.25))
			Geometry.beam(leg,knee,foot,0.085,shell.lightened(0.10))
			actor.legs.append(leg)
		for i in range(3):
			var eye := Geometry.sphere(root,Vector3(side*(0.13+i*0.12),0.71-i*0.055,-0.80+i*0.06),Vector3.ONE*(0.1 if i else 0.14),marks)
			eye.material_override = Geometry.material(marks,0.65)
		Geometry.beam(root,Vector3(side*0.23,0.45,-0.68),Vector3(side*0.32,0.26,-1.06),0.13,Color("b9b399"))
		Geometry.beam(root,Vector3(side*0.32,0.26,-1.06),Vector3(side*0.15,0.22,-1.16),0.08,Color("cac5aa"))
	for i in range(4):
		Geometry.sphere(root,Vector3(0,1.09-i*0.015,0.17+i*0.22),Vector3(0.33,0.055,0.14),marks)
	if queen:
		for side in [-1,1]:
			for i in range(3):
				Geometry.cylinder(root,Vector3(side*0.40,1.1,0.1+i*0.32),0.10,0.48,marks,0,5)
		Geometry.sphere(root,Vector3(0,0.46,1.12),Vector3(0.85,0.65,0.7),Color("77765b"))
