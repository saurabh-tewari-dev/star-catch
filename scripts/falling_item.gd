extends Area2D

enum Kind { STAR, ROCK }

var kind: Kind = Kind.STAR
var fall_speed: float = 240.0
var points: int = 1
var _spin := 0.0
var _visual: Node2D


func setup(item_kind: Kind, speed: float) -> void:
	kind = item_kind
	fall_speed = speed
	points = 1 if kind == Kind.STAR else 0
	if kind == Kind.STAR:
		add_to_group("star")
	else:
		add_to_group("rock")


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	monitoring = true
	monitorable = true
	_spin = randf_range(-1.8, 1.8)
	_build_collision()
	_build_visuals()


func _process(delta: float) -> void:
	position.y += fall_speed * delta
	if _visual:
		_visual.rotation += _spin * delta
	if position.y > get_viewport_rect().size.y + 80.0:
		queue_free()


func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20.0 if kind == Kind.STAR else 22.0
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	if kind == Kind.STAR:
		_visual.add_child(_make_star(22.0, 10.0, Color("ffe566")))
		_visual.add_child(_make_star(10.0, 4.0, Color("fff6b0")))
	else:
		_visual.add_child(_make_circle(20.0, Color("8b7d8a")))
		_visual.add_child(_make_circle(12.0, Color("5c534f"), Vector2(-4, -3)))


func _make_star(outer: float, inner: float, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	var points := PackedVector2Array()
	for i in 10:
		var angle := deg_to_rad(-90.0 + float(i) * 36.0)
		var radius := outer if i % 2 == 0 else inner
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	poly.polygon = points
	return poly


func _make_circle(radius: float, color: Color, offset := Vector2.ZERO) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	poly.position = offset
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * float(i) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	poly.polygon = points
	return poly
