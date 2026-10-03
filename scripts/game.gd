extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const FallingScript := preload("res://scripts/falling_item.gd")

enum State { MENU, PLAYING, GAME_OVER }

var _state: State = State.MENU
var _score := 0
var _lives := 3
var _spawn_timer := 0.0
var _elapsed := 0.0
var _player: Area2D
var _hud: Label
var _banner: Label
var _hint: Label
var _items := Node2D.new()
var _stars: Array[Dictionary] = []


func _ready() -> void:
	_build_background()
	_items.name = "Items"
	add_child(_items)
	_build_player()
	_build_hud()
	_show_menu()


func _process(delta: float) -> void:
	_twinkle(delta)
	if _state != State.PLAYING:
		return
	_elapsed += delta
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_item()
		_spawn_timer = _spawn_interval()


func _unhandled_input(event: InputEvent) -> void:
	if _state == State.PLAYING:
		return
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	if event.is_action_pressed("ui_accept") or clicked or tapped:
		_start_game()
		get_viewport().set_input_as_handled()


func _build_player() -> void:
	_player = PlayerScript.new()
	_player.position = Vector2(360, 960)
	_player.set_playfield_width(720)
	_player.caught_star.connect(_on_caught_star)
	_player.hit_rock.connect(_on_hit_rock)
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_player)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

	_hud = Label.new()
	_hud.position = Vector2(24, 20)
	_hud.add_theme_font_size_override("font_size", 28)
	_hud.add_theme_color_override("font_color", Color("f4fbff"))
	ui.add_child(_hud)

	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.offset_left = 40
	_banner.offset_top = 280
	_banner.offset_right = -40
	_banner.offset_bottom = -400
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 48)
	_banner.add_theme_color_override("font_color", Color("ffe566"))
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(_banner)

	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hint.offset_left = 40
	_hint.offset_top = 620
	_hint.offset_right = -40
	_hint.offset_bottom = -280
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 0.85))
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(_hint)
	_refresh_hud()


func _build_background() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 48:
		var star := Polygon2D.new()
		star.color = Color(1, 1, 1, rng.randf_range(0.18, 0.7))
		star.position = Vector2(rng.randf_range(12, 708), rng.randf_range(12, 1068))
		var radius := rng.randf_range(1.2, 2.6)
		star.polygon = PackedVector2Array([
			Vector2(-radius, 0),
			Vector2(0, -radius),
			Vector2(radius, 0),
			Vector2(0, radius),
		])
		add_child(star)
		_stars.append({ "node": star, "base": star.color.a, "phase": rng.randf() * TAU })

	var ground := ColorRect.new()
	ground.color = Color(0.09, 0.12, 0.22, 1)
	ground.position = Vector2(0, 1000)
	ground.size = Vector2(720, 80)
	add_child(ground)


func _twinkle(delta: float) -> void:
	for star in _stars:
		star["phase"] = float(star["phase"]) + delta * 2.2
		var node: Polygon2D = star["node"]
		var color := node.color
		color.a = float(star["base"]) * (0.55 + 0.45 * (0.5 + 0.5 * sin(float(star["phase"]))))
		node.color = color


func _show_menu() -> void:
	_state = State.MENU
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_banner.text = "Star Catch"
	_hint.text = "Catch stars. Dodge rocks.\nA/D or arrows to move, click or drag on web.\nPress Space or click to start."
	_refresh_hud()


func _start_game() -> void:
	_clear_items()
	_score = 0
	_lives = 3
	_elapsed = 0.0
	_spawn_timer = 0.4
	_state = State.PLAYING
	_player.position = Vector2(360, 960)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_banner.text = ""
	_hint.text = ""
	_refresh_hud()


func _game_over() -> void:
	_state = State.GAME_OVER
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_banner.text = "Game over"
	_hint.text = "You scored %d.\nPress Space or click to try again." % _score
	_refresh_hud()


func _spawn_item() -> void:
	var item = FallingScript.new()
	var rock_chance := clampf(0.18 + _elapsed * 0.012, 0.18, 0.42)
	var kind = FallingScript.Kind.ROCK if randf() < rock_chance else FallingScript.Kind.STAR
	var speed := lerpf(210.0, 420.0, clampf(_elapsed / 50.0, 0.0, 1.0))
	speed *= randf_range(0.86, 1.14)
	item.setup(kind, speed)
	item.position = Vector2(randf_range(48.0, 672.0), -40.0)
	_items.add_child(item)


func _spawn_interval() -> float:
	return lerpf(0.85, 0.38, clampf(_elapsed / 45.0, 0.0, 1.0))


func _on_caught_star(points: int) -> void:
	if _state != State.PLAYING:
		return
	_score += max(points, 1)
	_refresh_hud()


func _on_hit_rock() -> void:
	if _state != State.PLAYING:
		return
	_lives -= 1
	_refresh_hud()
	if _lives <= 0:
		_game_over()


func _clear_items() -> void:
	for child in _items.get_children():
		child.queue_free()


func _refresh_hud() -> void:
	_hud.text = "Score %d    Lives %d" % [_score, _lives]
