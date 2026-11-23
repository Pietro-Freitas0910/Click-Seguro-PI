extends Control

const GAME_SCENE: String = "res://scenes/game.tscn"

@onready var window: Control = %Window
@onready var action_frame: Control = %ActionFrame
@onready var play_button: Button = %PlayButton
@onready var exit_button: Button = %ExitButton
@onready var record_label: Label = %RecordLabel
@onready var sound_button: Button = %SoundButton
@onready var text_size_button: Button = %TextSizeButton
@onready var text_speed_button: Button = %TextSpeedButton


func _ready() -> void:
	play_button.pressed.connect(SceneTransition.change_scene.bind(GAME_SCENE))
	exit_button.pressed.connect(get_tree().quit)
	sound_button.pressed.connect(_toggle_sound)
	text_size_button.pressed.connect(_toggle_text_size)
	text_speed_button.pressed.connect(_cycle_text_speed)
	# No navegador não existe "fechar o jogo", então o botão Sair some.
	exit_button.visible = not OS.has_feature("web")

	_update_record_label()
	_update_option_buttons()
	play_button.grab_focus()
	_play_intro()


## Recorde e contador de impacto (todas as partidas jogadas neste navegador).
func _update_record_label() -> void:
	record_label.visible = GameState.games_played > 0 or GameState.best_score > 0
	record_label.text = "Recorde: %d pontos  |  Partidas: %d  |  Golpes identificados: %d" % [
		GameState.best_score, GameState.games_played, GameState.scams_spotted]


func _toggle_sound() -> void:
	GameState.set_sound(not GameState.sound_on)
	_update_option_buttons()


func _toggle_text_size() -> void:
	GameState.set_large_text(not GameState.large_text)
	_update_option_buttons()


func _cycle_text_speed() -> void:
	GameState.cycle_text_speed()
	_update_option_buttons()


func _update_option_buttons() -> void:
	sound_button.text = "SOM: LIGADO" if GameState.sound_on else "SOM: DESLIGADO"
	text_size_button.text = "LETRA: GRANDE" if GameState.large_text else "LETRA: NORMAL"
	text_speed_button.text = "TEXTO: " + GameState.TEXT_SPEED_NAMES[GameState.text_speed]


func _play_intro() -> void:
	# A janela "abre" na tela do computador, como um programa.
	window.pivot_offset = window.size / 2.0
	window.scale = Vector2(0.9, 0.9)
	window.modulate.a = 0.0
	action_frame.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(window, "modulate:a", 1.0, 0.25).set_delay(0.2)
	tween.parallel().tween_property(window, "scale", Vector2.ONE, 0.35).set_delay(0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_callback(Audio.play.bind("window_open", -6.0)).set_delay(0.2)
	tween.tween_property(action_frame, "modulate:a", 1.0, 0.3)
