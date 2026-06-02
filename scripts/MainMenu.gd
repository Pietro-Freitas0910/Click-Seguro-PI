extends Control

const GAME_SCENE: String = "res://scenes/Game.tscn"

@onready var play_button: Button = %PlayButton
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_exit_pressed() -> void:
	get_tree().quit()
