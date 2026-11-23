class_name TypewriterLabel
extends Label
## Label que "digita" o texto letra por letra.

signal typing_finished

## Segundos por letra.
@export var seconds_per_char: float = 0.018
## Toca um "tec" de teclado enquanto digita.
@export var typing_sound: bool = false

var _elapsed: float = 0.0
var _seconds: float = 0.018
var _last_sound_char: int = 0


func _ready() -> void:
	set_process(false)


func type_text(value: String) -> void:
	text = value
	# A opção de velocidade do texto vale para todo o jogo (NA HORA = sem digitar).
	var factor: float = GameState.typing_factor()
	if factor <= 0.0:
		finish_typing()
		return
	_seconds = seconds_per_char * factor
	visible_characters = 0
	_elapsed = 0.0
	_last_sound_char = 0
	set_process(true)


func finish_typing() -> void:
	visible_characters = -1
	set_process(false)
	typing_finished.emit()


func _process(delta: float) -> void:
	_elapsed += delta
	var count: int = int(_elapsed / _seconds)
	if count >= get_total_character_count():
		finish_typing()
		return
	visible_characters = count
	if typing_sound and count - _last_sound_char >= 3:
		_last_sound_char = count
		Audio.play("type", -6.0, 0.15)
