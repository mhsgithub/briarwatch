class_name UndeadVisual
extends RefCounted
## Art-only articulated bodies, sharing ActorVisual's animation hooks.
static func build(actor: ActorVisual) -> void:
	var skeleton := actor.style == "skeletal_archer"
	var soldier := actor.style in ["corvin","risen_soldier"]
	var alive := actor.style == "corvin"
	var bone := Color("b6b39b")
	var skin := Color("a9957d") if alive else Color("73816b")
	var cloth := Color("354c4b") if soldier else Color("45443b")
	var steel := Color("617675")
	var gold := Color("b49b67")
	var root := actor.pivot
	for side in [-1,1]:
		var leg := Node3D.new()
		root.add_child(leg)
		leg.position = Vector3(side*0.21,0.77,0)
		Geometry.beam(leg,Vector3.ZERO,Vector3(side*0.035,-0.38,0.05),0.095 if skeleton else 0.21,bone if skeleton else cloth)
		Geometry.beam(leg,Vector3(side*0.035,-0.38,0.05),Vector3(0,-0.64,-0.04),0.08 if skeleton else 0.17,bone if skeleton else Color("3d3930"))
		Geometry.box(leg,Vector3(0,-0.68,-0.1),Vector3(0.19,0.13,0.32),bone if skeleton else Color("342e28"))
		actor.legs.append(leg)
	if skeleton:
		Geometry.beam(root,Vector3(0,0.8,0),Vector3(0,1.62,0),0.10,bone)
		for i in range(5):
			var rib := Geometry.ring(root,0.29-i*0.022,bone,0.038)
			rib.position.y = 1.45-i*0.105
			rib.scale.z = 0.7
		Geometry.box(root,Vector3(0,0.83,0),Vector3(0.48,0.17,0.24),bone)
	else:
		Geometry.cylinder(root,Vector3(0,1.17,0),0.30,0.76,cloth,0.43,7)
		for i in range(5):
			var rag := Geometry.box(root,Vector3(-0.3+i*0.15,0.72-(i%2)*0.05,-0.16),Vector3(0.16,0.3,0.26),cloth.darkened((i%3)*0.1))
			rag.rotation.z = (i-2)*0.08
		if soldier:
			Geometry.cylinder(root,Vector3(0,1.24,-0.025),0.35,0.58,steel,0.43,8)
			Geometry.box(root,Vector3(0,1.23,-0.365),Vector3(0.12,0.51,0.04),gold)
			Geometry.box(root,Vector3(0,1.29,-0.395),Vector3(0.22,0.22,0.04),Color("2b4440"))
			Geometry.sphere(root,Vector3(0,1.29,-0.428),Vector3(0.075,0.12,0.025),gold)
			for side in [-1,1]: Geometry.sphere(root,Vector3(side*0.43,1.51,0),Vector3(0.46,0.23,0.47),steel)
		else:
			Geometry.box(root,Vector3(0.18,1.28,-0.29),Vector3(0.23,0.35,0.10),skin)
			for i in range(3): Geometry.beam(root,Vector3(0.08,1.36-i*0.09,-0.36),Vector3(0.26,1.33-i*0.09,-0.36),0.03,Color("999b82"))
	Geometry.sphere(root,Vector3(0,1.87,-0.045),Vector3(0.47,0.49,0.43),bone if skeleton else skin)
	Geometry.box(root,Vector3(0,1.65,-0.12),Vector3(0.29,0.13,0.28),bone if skeleton else skin.darkened(0.15))
	for side in [-1,1]:
		Geometry.sphere(root,Vector3(side*0.105,1.86,-0.24),Vector3(0.11,0.095,0.055),Color("151e1c"))
		if not alive:
			var eye := Geometry.sphere(root,Vector3(side*0.105,1.86,-0.273),Vector3(0.045,0.035,0.025),Color("a2bf67"))
			eye.material_override = Geometry.material(Color("a2bf67"),1.2)
		var arm := Node3D.new()
		root.add_child(arm)
		arm.position = Vector3(side*0.42,1.45,0)
		Geometry.beam(arm,Vector3.ZERO,Vector3(side*0.10,-0.34,-0.08),0.085 if skeleton else 0.19,bone if skeleton else cloth)
		Geometry.beam(arm,Vector3(side*0.10,-0.34,-0.08),Vector3(side*0.1,-0.43,-0.43),0.08 if skeleton else 0.16,bone if skeleton else skin)
		Geometry.sphere(arm,Vector3(side*0.1,-0.44,-0.45),Vector3(0.17,0.19,0.16),bone if skeleton else skin)
		actor.fists.append(arm)
	if soldier:
		Geometry.sphere(root,Vector3(0,2.01,0),Vector3(0.53,0.25,0.48),steel)
		Geometry.box(root,Vector3(0,2.04,-0.23),Vector3(0.55,0.08,0.17),steel.lightened(0.15))
		if alive:
			Geometry.beam(root,Vector3(-0.34,1.45,-0.31),Vector3(0.33,0.89,-0.32),0.07,Color("ccc5ad"))
		else:
			actor.weapon = Node3D.new()
			root.add_child(actor.weapon)
			actor.weapon.position = Vector3(0.58,1.08,-0.29)
			Geometry.box(actor.weapon,Vector3(0,0,-0.2),Vector3(0.12,0.14,0.65),Color("302c27"))
			Geometry.box(actor.weapon,Vector3(0,0,-0.48),Vector3(0.63,0.11,0.12),gold)
			Geometry.box(actor.weapon,Vector3(0,0,-1.2),Vector3(0.3,0.065,1.46),steel.lightened(0.2))
			Geometry.box(actor.weapon,Vector3(0,0.045,-1.18),Vector3(0.07,0.02,1.25),Color("6d8150"))
	elif skeleton:
		actor.weapon = Node3D.new()
		root.add_child(actor.weapon)
		actor.weapon.position = Vector3(0.51,1.15,-0.39)
		for i in range(10):
			var a := -1.3+i*0.26
			var b := a+0.26
			Geometry.beam(actor.weapon,Vector3(0,sin(a)*0.78,-cos(a)*0.38),Vector3(0,sin(b)*0.78,-cos(b)*0.38),0.055,Color("73654e"))
		Geometry.beam(actor.weapon,Vector3(0,-0.74,-0.10),Vector3(0,0.74,-0.10),0.013,bone)
		Geometry.cylinder(root,Vector3(0.24,1.28,0.25),0.12,0.8,Color("3c3930"))
