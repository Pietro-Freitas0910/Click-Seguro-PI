extends Label

@export var text_speed: float = 0.018

var full_text: String = ""
var char_index: int = 0
var is_typing: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	set_process(true)


func type_text(value: String) -> void:
	full_text = value
	text = value
	visible_characters = 0
	char_index = 0
	_elapsed = 0.0
	is_typing = true


func finish_typing() -> void:
	is_typing = false
	char_index = full_text.length()
	visible_characters = -1


func _process(delta: float) -> void:
	if not is_typing:
		return

	_elapsed += delta
	var next_index: int = int(_elapsed / text_speed)
	if next_index <= char_index:
		return

	char_index = min(next_index, full_text.length())
	visible_characters = char_index

	if char_index >= full_text.length():
		finish_typing()
