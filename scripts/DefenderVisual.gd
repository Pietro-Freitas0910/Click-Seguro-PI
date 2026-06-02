extends TextureRect

@export var sprite_sheet: Texture2D = null
@export var columns: int = 4
@export var rows: int = 4
@export var state: String = "typing"
@export var frame_interval: float = 0.15
@export var jitter_strength: float = 1.2
@export var feedback_duration: float = 1.05

var _animations: Dictionary = {}
var _frames: Dictionary = {}
var _time: float = 0.0
var _frame_time: float = 0.0
var _frame_index: int = 0
var _base_position: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
var _base_modulate: Color = Color.WHITE
var _rest_state: String = "typing"
var _feedback_boost: float = 0.0
var _feedback_serial: int = 0


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
	_rest_state = state
	set_state(state)
	set_process(true)


func _setup_animations() -> void:
	_animations = {
		"idle": [0, 1],
		"typing": [0, 1, 2, 1],
		"sleepy": [3],
		"protected": [4, 5, 6, 7],
		"success": [4, 5, 6, 7],
		"alert": [8, 9, 10, 11],
		"panic": [9, 10, 11, 8],
		"under_attack": [8, 10, 11],
		"victory": [12, 13, 14, 13],
		"calm": [12, 15, 12],
		"defeat": [8, 10, 11, 10]
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

	var pulse: float = 1.0 + _feedback_boost + sin(_time * 2.4) * 0.016
	scale = _base_scale * pulse

	if state == "alert" or state == "panic" or state == "under_attack" or state == "defeat":
		var offset_x: float = sin(_time * 24.0) * jitter_strength
		position = _base_position + Vector2(offset_x, 0.0)
	else:
		position = _base_position

	if state == "success" or state == "protected" or state == "victory" or state == "calm":
		modulate = Color(0.62, 1.0, 0.86, 0.9 + abs(sin(_time * 5.0)) * 0.1)
	elif state == "alert" or state == "panic" or state == "under_attack":
		modulate = Color(1.0, 0.62, 0.52, 0.84 + abs(sin(_time * 7.0)) * 0.14)
	elif state == "defeat":
		modulate = Color(1.0, 0.22, 0.18, 0.62 + abs(sin(_time * 8.0)) * 0.18)
	else:
		modulate = _base_modulate


func set_state(new_state: String) -> void:
	if not _animations.has(new_state):
		new_state = "typing"

	state = new_state
	_frame_index = 0
	_apply_current_frame()


func trigger_feedback(is_success: bool) -> void:
	_feedback_serial += 1
	var current_serial: int = _feedback_serial

	if is_success:
		set_state("success")
	else:
		set_state("panic")

	_feedback_boost = 0.1
	var tween: Tween = create_tween()
	tween.tween_property(self, "_feedback_boost", 0.0, 0.32)
	await get_tree().create_timer(feedback_duration).timeout
	if is_inside_tree() and current_serial == _feedback_serial:
		set_state(_rest_state)


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
