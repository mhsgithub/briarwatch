class_name VitalityOrb
extends Control
var ratio: float = 1.0
var phase: float = 0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	phase+=delta
	queue_redraw()
func _draw() -> void:
	var center:=size*0.5
	var radius:=minf(size.x,size.y)*0.42
	draw_circle(center,radius+7,Color("0c1215"))
	draw_arc(center,radius+6,0,TAU,96,Color("9e8658"),2,true)
	draw_arc(center,radius+2,0,TAU,96,Color("524632"),2,true)
	draw_circle(center,radius,Color("241318"))
	var polygon:=PackedVector2Array()
	var top:=radius*(1.0-2.0*clampf(ratio,0,1))
	for i in range(97):
		var a:=float(i)/96.0*TAU
		var p:=Vector2(cos(a),sin(a))*radius
		if p.y>=top:
			polygon.append(center+p)
	if polygon.size()>=3:
		draw_colored_polygon(polygon,Color("a13735"))
		# Concentric shaded liquid clipped to the same health level.
		for layer in range(12):
			var r:=radius*(1.0-float(layer)*0.04)
			var tint:=Color("4e1826").lerp(Color("bf443d"),float(layer)/11.0)
			var liquid:=PackedVector2Array()
			for i in range(97):
				var a:=float(i)/96.0*TAU
				var p:=Vector2(cos(a),sin(a))*r
				if p.y>=top: liquid.append(center+p)
			if liquid.size()>=3: draw_colored_polygon(liquid,tint)
		var inner:=radius*0.72
		draw_arc(center+Vector2(-radius*0.10,radius*0.08),inner,0.2,2.8,48,Color(0.95,0.34,0.24,0.25),4,true)
	draw_arc(center,radius-5,3.8,4.7,32,Color(1,0.86,0.67,0.38),3,true)
	draw_circle(center+Vector2(-radius*0.36,-radius*0.48),radius*0.10,Color(1,0.93,0.83,0.38))
	for side in [-1,1]:
		var x: float=center.x+side*(radius+9)
		draw_colored_polygon(PackedVector2Array([Vector2(x,center.y-10),Vector2(x+side*8,center.y),Vector2(x,center.y+10)]),Color("8d784e"))
