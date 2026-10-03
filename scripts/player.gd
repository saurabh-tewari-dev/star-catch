extends Area2D

signal caught_star(points: int)
signal hit_rock

const SPEED := 460.0
const FOLLOW_SPEED := 920.0

var _bounds := Vector2(48.0, 672.0)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	_build_visuals()
	_build_collision()


func set_playfield_width(width: float) -> void:
	_bounds = Vector2(48.0, width - 48.0)
	position.x = clampf(position.x, _bounds.x, _bounds.y)


func _process(delta: float) -> void:
	var dir := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1.0

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var target_x := get_viewport().get_mouse_position().x
		position.x = move_toward(position.x, target_x, FOLLOW_SPEED * delta)
	else:
		position.x += dir * SPEED * delta

	position.x = clampf(position.x, _bounds.x, _bounds.y)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("star"):
		var points := 1
		if "points" in area:
			points = int(area.points)
		caught_star.emit(points)
		area.queue_free()
	elif area.is_in_group("rock"):
		hit_rock.emit()


func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(84, 36)
	collision.shape = shape
	collision.position = Vector2(0, 4)
	add_child(collision)


func _build_visuals() -> void:
	var glow := _circle(Vector2(0, 8), 46, Color(0.49, 0.88, 1.0, 0.16))
	add_child(glow)

	var bowl := Polygon2D.new()
	bowl.color = Color("7ee0ff")
	bowl.polygon = PackedVector2Array([
		Vector2(-42, -6),
		Vector2(42, -6),
		Vector2(34, 22),
		Vector2(-34, 22),
	])
	add_child(bowl)

	var rim := Polygon2D.new()
	rim.color = Color("ffe566")
	rim.polygon = PackedVector2Array([
		Vector2(-46, -14),
		Vector2(46, -14),
		Vector2(40, -2),
		Vector2(-40, -2),
	])
	add_child(rim)

	var cabin := _circle(Vector2(0, -8), 16, Color("f4fbff"))
	add_child(cabin)


func _circle(offset: Vector2, radius: float, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	poly.position = offset
	var points := PackedVector2Array()
	for i in 20:
		var angle := TAU * float(i) / 20.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	poly.polygon = points
	return poly
