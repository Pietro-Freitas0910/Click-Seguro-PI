extends Control
## Tela principal da partida.
##
## A cada rodada chega uma mensagem no computador (e-mail, mensagens, SMS,
## ligação, QR Code, boleto...). O jogador escolhe uma ação, vê as pistas destacadas e o
## feedback, e aperta CONTINUAR quando terminar de ler.

enum Result { BEST, SAFE, NEUTRAL, UNSAFE }

const END_SCENE: String = "res://scenes/end_screen.tscn"
const MAX_LIVES: int = 3
const THREAT_STEP: int = 34
const MENU_SCENE: String = "res://scenes/main_menu.tscn"
## Quantas vezes procurar a voz em português (no navegador ela demora a carregar).
const TTS_ATTEMPTS: int = 12
const TTS_RETRY_SECONDS: float = 0.5
## Tempo para confirmar a saída com um segundo clique no botão MENU.
const MENU_CONFIRM_SECONDS: float = 3.0
const PROMPT_FONT_SIZE: int = 18
const FEEDBACK_FONT_SIZE: int = 17

const COLOR_INFO := Color(0.45, 0.85, 1.0)
const COLOR_BEST := Color(0.3, 1.0, 0.56)
const COLOR_SAFE := Color(0.35, 0.9, 1.0)
const COLOR_NEUTRAL := Color(1.0, 0.78, 0.25)
const COLOR_DANGER := Color(1.0, 0.25, 0.3)

const RESULTS := {
	Result.BEST: {"id": "best", "title": "RESPOSTA IDEAL", "points": 10, "color": COLOR_BEST, "sound": "correct"},
	Result.SAFE: {"id": "safe", "title": "RESPOSTA SEGURA", "points": 6, "color": COLOR_SAFE, "sound": "correct"},
	Result.NEUTRAL: {"id": "neutral", "title": "RESPOSTA PARCIAL", "points": 2, "color": COLOR_NEUTRAL, "sound": "partial"},
	Result.UNSAFE: {"id": "unsafe", "title": "RESPOSTA INSEGURA", "points": -5, "color": COLOR_DANGER, "sound": "wrong"},
}

var score: int = 0
var lives: int = MAX_LIVES
var threat: int = 0
var challenges: Array[Dictionary] = []
var challenge_index: int = 0
var _waiting_answer: bool = false
var _shown_score: int = 0
var _feedback_style: StyleBoxFlat
var _tts_voice: String = ""
var _round_started: bool = false
var _menu_armed: bool = false
var _menu_arm_id: int = 0

@onready var stage: Stage = %Stage
@onready var hacker: SceneCharacter = stage.hacker
@onready var player: SceneCharacter = stage.player
@onready var window: Control = %Window
@onready var screen_flash: ColorRect = %ScreenFlash
@onready var challenge_counter_label: Label = %ChallengeCounterLabel
@onready var prompt_label: TypewriterLabel = %PromptLabel
@onready var listen_button: Button = %ListenButton
@onready var challenge_view: ChallengeView = %ChallengeView
@onready var feedback_panel: PanelContainer = %FeedbackPanel
@onready var feedback_label: TypewriterLabel = %FeedbackLabel
@onready var continue_button: Button = %ContinueButton
@onready var score_label: Label = %ScoreLabel
@onready var lives_label: Label = %LivesLabel
@onready var threat_bar: ProgressBar = %ThreatBar
@onready var sound_button: Button = %SoundButton
@onready var tutorial: Control = %Tutorial
@onready var tutorial_ok_button: Button = %OkButton
@onready var help_button: Button = %HelpButton
@onready var menu_button: Button = %MenuButton
@onready var action_buttons: Dictionary = {
	"Abrir": %AbrirButton,
	"Ignorar": %IgnorarButton,
	"Denunciar": %DenunciarButton,
	"Bloquear": %BloquearButton,
}


func _ready() -> void:
	for action: String in action_buttons:
		var button: Button = action_buttons[action]
		button.pressed.connect(_on_action_pressed.bind(action))
	continue_button.pressed.connect(_next_challenge)
	listen_button.pressed.connect(_speak_challenge)
	sound_button.pressed.connect(_toggle_sound)
	tutorial_ok_button.pressed.connect(_close_tutorial)
	help_button.pressed.connect(_open_tutorial)
	menu_button.pressed.connect(_on_menu_pressed)

	_feedback_style = feedback_panel.get_theme_stylebox("panel").duplicate()
	feedback_panel.add_theme_stylebox_override("panel", _feedback_style)
	_setup_tts()
	_update_sound_button()
	_apply_text_size()

	GameState.start_run()
	challenges = Challenges.pick_round()
	_refresh_hud(false)
	_open_window()

	if GameState.tutorial_seen:
		_load_challenge()
	else:
		_open_tutorial()


# --- Fluxo da partida ---------------------------------------------------------

func _load_challenge() -> void:
	_round_started = true
	var challenge: Dictionary = challenges[challenge_index]
	challenge_counter_label.text = "%d/%d" % [challenge_index + 1, challenges.size()]
	prompt_label.type_text(challenge["prompt"])
	challenge_view.show_challenge(challenge)
	for action: String in action_buttons:
		(action_buttons[action] as Button).text = Challenges.label_for(challenge, action)
	_show_feedback("Analise a mensagem e escolha uma ação.", COLOR_INFO)
	continue_button.visible = false
	_set_buttons_enabled(true)
	_waiting_answer = true
	Audio.play("notify", -4.0)


func _on_action_pressed(action: String) -> void:
	if not _waiting_answer:
		return
	_waiting_answer = false
	_set_buttons_enabled(false)
	prompt_label.finish_typing()
	_stop_speaking()

	var challenge: Dictionary = challenges[challenge_index]
	var result: Result = _classify(challenge, action)
	var info: Dictionary = RESULTS[result]
	var points: int = info["points"]
	var color: Color = info["color"]

	score = max(score + points, 0)
	if result == Result.UNSAFE:
		lives -= 1
		threat = min(threat + THREAT_STEP, 100)
	GameState.register_answer(challenge, action, info["id"])

	var explanation: String = challenge["feedback"].get(action, "")
	_show_feedback("%s (%+d)  %s" % [info["title"], points, explanation], color)
	_highlight_button(action_buttons[action], color)
	challenge_view.reveal_clues()
	_play_reaction(result)
	Audio.play(info["sound"], -2.0)
	_refresh_hud(true)

	continue_button.text = "VER RESULTADO" if lives <= 0 or challenge_index + 1 >= challenges.size() else "CONTINUAR"
	continue_button.visible = true
	continue_button.modulate.a = 0.0
	create_tween().tween_property(continue_button, "modulate:a", 1.0, 0.3).set_delay(0.4)
	continue_button.grab_focus()


func _next_challenge() -> void:
	_stop_speaking()
	if lives <= 0:
		_finish_game(false)
		return
	challenge_index += 1
	if challenge_index >= challenges.size():
		_finish_game(true)
		return
	_load_challenge()


func _classify(challenge: Dictionary, action: String) -> Result:
	if Challenges.is_best(challenge, action):
		return Result.BEST
	if challenge["safe"].has(action):
		return Result.SAFE
	if challenge["neutral"].has(action):
		return Result.NEUTRAL
	return Result.UNSAFE


func _finish_game(did_win: bool) -> void:
	GameState.set_result(score, did_win)
	SceneTransition.change_scene(END_SCENE)


# --- Tutorial, som e leitura em voz alta ----------------------------------------

## Aumenta o texto do contexto e do feedback quando "Letra grande" está ligada.
## (O texto da mensagem em si é ajustado pelo ChallengeView.)
func _apply_text_size() -> void:
	var text_scale: float = GameState.text_scale()
	prompt_label.add_theme_font_size_override("font_size", roundi(PROMPT_FONT_SIZE * text_scale))
	feedback_label.add_theme_font_size_override("font_size", roundi(FEEDBACK_FONT_SIZE * text_scale))


## Abre o "Como jogar". Na primeira vez aparece sozinho; depois, pelo botão AJUDA.
func _open_tutorial() -> void:
	if tutorial.visible:
		return
	_stop_speaking()
	tutorial.visible = true
	tutorial.modulate.a = 0.0
	var delay: float = 0.0 if _round_started else 0.3
	create_tween().tween_property(tutorial, "modulate:a", 1.0, 0.3).set_delay(delay)
	tutorial_ok_button.grab_focus()


func _close_tutorial() -> void:
	GameState.mark_tutorial_seen()
	var tween: Tween = create_tween()
	tween.tween_property(tutorial, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void: tutorial.visible = false)
	# Se a partida já começou, só fecha a ajuda e volta para o mesmo desafio.
	if not _round_started:
		_load_challenge()


## Voltar ao menu pede um segundo clique, para ninguém perder a partida sem querer.
func _on_menu_pressed() -> void:
	if _menu_armed:
		_stop_speaking()
		SceneTransition.change_scene(MENU_SCENE)
		return
	_menu_armed = true
	_menu_arm_id += 1
	var arm_id: int = _menu_arm_id
	menu_button.text = "SAIR MESMO?"
	_pop(menu_button, COLOR_NEUTRAL)
	await get_tree().create_timer(MENU_CONFIRM_SECONDS).timeout
	if is_inside_tree() and arm_id == _menu_arm_id:
		_menu_armed = false
		menu_button.text = "MENU"


func _toggle_sound() -> void:
	GameState.set_sound(not GameState.sound_on)
	_update_sound_button()


func _update_sound_button() -> void:
	sound_button.text = "SOM: LIGADO" if GameState.sound_on else "SOM: DESLIGADO"


## Usa a voz do navegador/sistema, se existir uma em português.
## No navegador a lista de vozes chega alguns instantes depois de a página
## abrir, então o jogo tenta de novo por alguns segundos antes de desistir.
func _setup_tts() -> void:
	listen_button.visible = false
	for _attempt in TTS_ATTEMPTS:
		var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language("pt")
		if not voices.is_empty():
			_tts_voice = voices[0]
			listen_button.visible = true
			return
		await get_tree().create_timer(TTS_RETRY_SECONDS).timeout
		if not is_inside_tree():
			return


func _speak_challenge() -> void:
	if _tts_voice == "":
		return
	_stop_speaking()
	var challenge: Dictionary = challenges[challenge_index]
	DisplayServer.tts_speak("%s %s" % [challenge["prompt"], challenge_view.spoken_text()], _tts_voice)


func _stop_speaking() -> void:
	if _tts_voice != "":
		DisplayServer.tts_stop()


# --- Visual -------------------------------------------------------------------

func _play_reaction(result: Result) -> void:
	match result:
		Result.BEST, Result.SAFE:
			hacker.react(&"blocked", 0.6, COLOR_BEST)
			player.react(&"protected", 0.8, COLOR_BEST)
			player.bounce()
			_flash(COLOR_BEST, 0.18)
		Result.NEUTRAL:
			player.react(&"cautious", 0.8, COLOR_NEUTRAL)
			hacker.glow(COLOR_NEUTRAL, 0.15)
		Result.UNSAFE:
			hacker.react(&"attack", 0.7, COLOR_DANGER)
			hacker.bounce(0.05)
			player.react(&"attacked", 0.9, COLOR_DANGER)
			player.shake(10.0, 0.45)
			_shake_window()
			_flash(COLOR_DANGER, 0.3)
			_pop(lives_label, COLOR_DANGER)
			get_tree().create_timer(0.15).timeout.connect(Audio.play.bind("lock_break", -3.0))


func _refresh_hud(animated: bool) -> void:
	lives_label.text = "Vidas: %d/%d" % [lives, MAX_LIVES]
	var ratio: float = threat / 100.0

	# O hacker muda de "humor" conforme a ameaça aumenta.
	if ratio >= 0.66:
		hacker.set_rest_animation(&"dominating")
	elif ratio >= 0.34:
		hacker.set_rest_animation(&"hacking")
	else:
		hacker.set_rest_animation(&"idle")
	stage.set_threat(ratio, animated)
	stage.set_lives(lives, animated)

	if not animated:
		threat_bar.value = threat
		_set_score_text(score)
		return

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(threat_bar, "value", float(threat), 0.6) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_score_text, _shown_score, score, 0.5)
	if score != _shown_score:
		_pop(score_label)


func _set_score_text(value: int) -> void:
	_shown_score = value
	score_label.text = "Pontos: %d" % value


func _show_feedback(message: String, color: Color) -> void:
	feedback_label.type_text(message)
	feedback_label.add_theme_color_override("font_color", color.lightened(0.2))
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_feedback_style, "border_color", color, 0.2)
	tween.tween_property(_feedback_style, "bg_color", color.darkened(0.88), 0.2)


func _set_buttons_enabled(enabled: bool) -> void:
	for button: Button in action_buttons.values():
		button.disabled = not enabled
		if enabled:
			button.remove_theme_stylebox_override("disabled")
			button.remove_theme_color_override("font_disabled_color")


## Deixa o botão escolhido marcado com a cor do resultado enquanto os outros apagam.
func _highlight_button(button: Button, color: Color) -> void:
	var style: StyleBoxFlat = button.get_theme_stylebox("normal").duplicate()
	style.border_color = color
	style.bg_color = color.darkened(0.8)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_disabled_color", color.lightened(0.3))


## A tela do computador pisca com a cor do resultado.
func _flash(color: Color, strength: float) -> void:
	screen_flash.color = Color(color.r, color.g, color.b, strength)
	create_tween().tween_property(screen_flash, "color:a", 0.0, 0.5)


## A janela treme dentro da tela, como se o sistema estivesse sendo atacado.
func _shake_window() -> void:
	var origin: Vector2 = window.position
	var tween: Tween = create_tween()
	for i in 6:
		var strength: float = 8.0 * (1.0 - i / 6.0)
		tween.tween_property(window, "position",
			origin + Vector2(randf_range(-strength, strength), randf_range(-strength * 0.5, strength * 0.5)), 0.04)
	tween.tween_property(window, "position", origin, 0.05)


## Abre a janela como um programa abrindo no computador.
func _open_window() -> void:
	window.pivot_offset = window.size / 2.0
	window.scale = Vector2(0.9, 0.9)
	window.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(window, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(window, "modulate:a", 1.0, 0.2)
	Audio.play("window_open", -6.0)


func _pop(label: Control, color: Color = Color.WHITE) -> void:
	label.pivot_offset = label.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * 1.18, 0.08)
	tween.parallel().tween_property(label, "modulate", color, 0.08)
	tween.tween_property(label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate", Color.WHITE, 0.4)
