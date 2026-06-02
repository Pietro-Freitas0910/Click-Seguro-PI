extends TextureRect

@export var sprite_sheet: Texture2D = null
@export var columns: int = 4
@export var rows: int = 4
@export var state: String = "idle"
@export var frame_interval: float = 0.14
@export var jitter_strength: float = 1.6
@export var feedback_duration: float = 1.15

var _animations: Dictionary = {}
var _frames: Dictionary = {}
var _time: float = 0.0
var _frame_time: float = 0.0
var _frame_index: int = 0
var _base_position: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
var _base_modulate: Color = Color.WHITE
var _threat_level: float = 0.0
var _feedback_boost: float = 0.0
var _feedback_serial: int = 0
var _temporary_state_active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if sprite_sheet == null:
		sprite_sheet = texture

	_base_position = position
	_base_scale = scale
	_base_modulate = modulate
	_setup_animations()
	_build_frames()
	set_state(state)
	set_process(true)


func _setup_animations() -> void:
	_animations = {
		"idle": [0, 1, 2, 3],
		"blink": [0, 2, 0, 3],
		"alert": [4, 5],
		"angry": [4, 5, 7],
		"glitch": [6, 8, 9, 10, 14],
		"attack": [7, 11, 10, 9],
		"intense_attack": [5, 7, 11, 14],
		"threat": [4, 5, 7, 11],
		"blocked": [14, 15, 14, 12],
		"defeated": [12, 13, 14, 15]
	}


func _build_frames() -> void:
	_frames.clear()
	if sprite_sheet == null or columns <= 0 or rows <= 0:
		return

	var sheet_size: Vector2 = sprite_sheet.get_size()
	var frame_width: float = floor(sheet_size.x / float(columns))
	var frame_height: float = floor(sheet_size.y / float(rows))

	for animation_state in _animations.keys():
		var frame_ids: Array = _animations[animation_state]
		var frame_textures: Array = []

		for frame_value in frame_ids:
			var frame_id: int = int(frame_value)
			var frame_column: int = frame_id % columns
			var frame_row: int = int(frame_id / columns)
			var atlas_texture: AtlasTexture = AtlasTexture.new()
			atlas_texture.atlas = sprite_sheet
			atlas_texture.region = Rect2(Vector2(float(frame_column) * frame_width, float(frame_row) * frame_height), Vector2(frame_width, frame_height))
			frame_textures.append(atlas_texture)

		_frames[animation_state] = frame_textures


func _process(delta: float) -> void:
	_time += delta
	_frame_time += delta
	if _frame_time >= frame_interval:
		_frame_time = 0.0
		_advance_frame()

	var pulse: float = 1.0 + _feedback_boost + sin(_time * 2.8 + _threat_level * 2.0) * (0.02 + _threat_level * 0.032)
	scale = _base_scale * pulse

	if state == "attack" or state == "intense_attack" or state == "glitch" or state == "threat":
		var offset_x: float = sin(_time * 30.0) * jitter_strength * (1.0 + _threat_level)
		var offset_y: float = cos(_time * 23.0) * jitter_strength * 0.5 * (1.0 + _threat_level)
		position = _base_position + Vector2(offset_x, offset_y)
	else:
		position = _base_position

	if state == "blocked" or state == "defeated":
		modulate = Color(0.54, 0.92, 1.0, 0.68 + abs(sin(_time * 4.0)) * 0.18)
	elif state == "attack" or state == "intense_attack" or state == "threat" or state == "angry":
		modulate = Color(1.0, 0.22, 0.18, 0.88 + abs(sin(_time * 8.0)) * 0.12)
	elif state == "glitch" or state == "alert":
		modulate = Color(0.68 + _threat_level * 0.24, 1.0 - _threat_level * 0.42, 0.88 - _threat_level * 0.34, 0.82 + abs(sin(_time * 10.0)) * 0.14)
	else:
		modulate = _base_modulate


func set_state(new_state: String) -> void:
	if not _animations.has(new_state):
		new_state = "idle"

	state = new_state
	_frame_index = 0
	_apply_current_frame()


func trigger_feedback(is_correct: bool) -> void:
	_feedback_serial += 1
	var current_serial: int = _feedback_serial
	_temporary_state_active = true

	if is_correct:
		set_state("blocked")
	else:
		if _threat_level >= 0.66:
			set_state("intense_attack")
		else:
			set_state("attack")

	_feedback_boost = 0.1
	var tween: Tween = create_tween()
	tween.tween_property(self, "_feedback_boost", 0.0, 0.32)
	await get_tree().create_timer(feedback_duration).timeout
	if is_inside_tree() and current_serial == _feedback_serial:
		_temporary_state_active = false
		_return_to_threat_state()


func trigger_alert() -> void:
	_feedback_serial += 1
	var current_serial: int = _feedback_serial
	_temporary_state_active = true

	if _threat_level >= 0.34:
		set_state("glitch")
	else:
		set_state("alert")

	_feedback_boost = 0.06
	var tween: Tween = create_tween()
	tween.tween_property(self, "_feedback_boost", 0.0, 0.28)
	await get_tree().create_timer(feedback_duration).timeout
	if is_inside_tree() and current_serial == _feedback_serial:
		_temporary_state_active = false
		_return_to_threat_state()


func set_threat_level(level: float) -> void:
	_threat_level = clamp(level, 0.0, 1.0)
	if _temporary_state_active:
		return

	if state == "idle" or state == "blink" or state == "alert" or state == "glitch" or state == "threat":
		_return_to_threat_state()


func _return_to_threat_state() -> void:
	if _threat_level >= 0.66:
		set_state("threat")
	elif _threat_level >= 0.34:
		set_state("glitch")
	elif _threat_level > 0.0:
		set_state("alert")
	else:
		set_state("idle")


func _advance_frame() -> void:
	var frame_textures: Array = _frames.get(state, [])
	if frame_textures.is_empty():
		return

	_frame_index = (_frame_index + 1) % frame_textures.size()
	_apply_current_frame()


func _apply_current_frame() -> void:
	var frame_textures: Array = _frames.get(state, [])
	if frame_textures.is_empty():
		return

	if _frame_index >= frame_textures.size():
		_frame_index = 0

	texture = frame_textures[_frame_index] as Texture2D
