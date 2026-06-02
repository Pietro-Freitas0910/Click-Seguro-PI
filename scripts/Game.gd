extends Control

const END_SCENE: String = "res://scenes/EndScreen.tscn"
const THREAT_STEP: int = 34
const BEST_ANSWER_SCORE: int = 10
const SAFE_ANSWER_SCORE: int = 6
const NEUTRAL_ANSWER_SCORE: int = 2
const UNSAFE_ANSWER_PENALTY: int = 5

var challenges: Array[Dictionary] = [
	{
		"text": "E-MAIL SUSPEITO: uma mensagem diz ser do banco e pede sua senha em um link urgente para evitar bloqueio da conta.",
		"best_answer": "Denunciar",
		"safe_answers": ["Bloquear"],
		"neutral_answers": ["Ignorar"],
		"feedback_map": {
			"Denunciar": "Excelente. Denunciar ajuda a remover o golpe e proteger outras pessoas.",
			"Bloquear": "Seguro. Bloquear corta o contato, mas denunciar tambem ajuda a conter o golpe.",
			"Ignorar": "Cautela. Ignorar evita o clique, mas denunciar seria mais completo.",
			"Abrir": "Risco alto. Abrir o link pode entregar sua senha ao criminoso."
		}
	},
	{
		"text": "WHATSAPP FALSO: uma mensagem promete um premio se voce enviar CPF, telefone e codigo recebido por SMS.",
		"best_answer": "Denunciar",
		"safe_answers": ["Bloquear"],
		"neutral_answers": ["Ignorar"],
		"feedback_map": {
			"Denunciar": "Excelente. Denunciar reduz a circulacao do golpe no aplicativo.",
			"Bloquear": "Seguro. Bloquear impede novas mensagens desse contato.",
			"Ignorar": "Cautela. Ignorar evita o golpe, mas ele pode continuar circulando.",
			"Abrir": "Risco alto. Interagir com o golpe pode expor seus dados e codigos."
		}
	},
	{
		"text": "LINK DESCONHECIDO: um remetente anonimo envia um link encurtado que leva a uma pagina pedindo login.",
		"best_answer": "Bloquear",
		"safe_answers": ["Denunciar"],
		"neutral_answers": ["Ignorar"],
		"feedback_map": {
			"Bloquear": "Excelente. Bloquear o remetente impede novas tentativas diretas.",
			"Denunciar": "Seguro. Denunciar tambem ajuda, principalmente se a plataforma analisar o link.",
			"Ignorar": "Cautela. Ignorar evita o clique, mas o remetente ainda pode insistir.",
			"Abrir": "Risco alto. Links desconhecidos podem roubar credenciais."
		}
	},
	{
		"text": "ARQUIVO SUSPEITO: um desconhecido envia 'foto_ferias.exe' e insiste para voce abrir agora.",
		"best_answer": "Denunciar",
		"safe_answers": ["Bloquear"],
		"neutral_answers": ["Ignorar"],
		"feedback_map": {
			"Denunciar": "Excelente. Denunciar anexo suspeito ajuda a impedir malware.",
			"Bloquear": "Seguro. Bloquear evita novas tentativas desse remetente.",
			"Ignorar": "Cautela. Ignorar evita executar o arquivo, mas denunciar e melhor.",
			"Abrir": "Risco alto. Arquivos .exe inesperados podem instalar virus."
		}
	},
	{
		"text": "LIGACAO DE GOLPE: alguem diz ser do suporte e pede seu codigo de verificacao de duas etapas.",
		"best_answer": "Bloquear",
		"safe_answers": ["Denunciar"],
		"neutral_answers": ["Ignorar"],
		"feedback_map": {
			"Bloquear": "Excelente. Bloquear o numero corta a tentativa de engenharia social.",
			"Denunciar": "Seguro. Denunciar o numero tambem ajuda outras pessoas.",
			"Ignorar": "Cautela. Nao responder protege seu codigo, mas bloquear e melhor.",
			"Abrir": "Risco alto. Compartilhar ou seguir instrucoes do golpista pode liberar sua conta."
		}
	},
	{
		"text": "ATAQUE FINAL: o hacker tenta varios logins seguidos na sua conta enquanto uma sessao suspeita fica ativa.",
		"best_answer": "Bloquear",
		"safe_answers": ["Denunciar"],
		"neutral_answers": ["Ignorar"],
		"feedback_map": {
			"Bloquear": "Excelente. Bloquear a sessao suspeita corta o ataque imediatamente.",
			"Denunciar": "Seguro. Denunciar ajuda a plataforma a investigar a invasao.",
			"Ignorar": "Cautela insuficiente. Sem agir, o ataque pode continuar.",
			"Abrir": "Risco alto. Abrir caminhos ou confirmar acessos favorece o invasor."
		}
	}
]

var score: int = 0
var lives: int = 3
var threat: int = 0
var current_challenge_index: int = 0
var resolving_answer: bool = false

@onready var score_label: Label = %ScoreLabel
@onready var lives_label: Label = %LivesLabel
@onready var threat_bar: ProgressBar = %ThreatBar
@onready var challenge_counter_label: Label = %ChallengeCounterLabel
@onready var challenge_text_label: Label = %ChallengeTextLabel
@onready var feedback_panel: PanelContainer = %FeedbackPanel
@onready var feedback_label: Label = %FeedbackLabel
@onready var hacker_visual: TextureRect = %HackerVisual
@onready var defender_visual: TextureRect = %DefenderVisual
@onready var danger_overlay: ColorRect = %DangerOverlay
@onready var shield_overlay: ColorRect = %ShieldOverlay
@onready var threat_pulse: ColorRect = %ThreatPulse
@onready var security_center_mood: TextureRect = %SecurityCenterMood
@onready var abrir_button: Button = %AbrirButton
@onready var ignorar_button: Button = %IgnorarButton
@onready var denunciar_button: Button = %DenunciarButton
@onready var bloquear_button: Button = %BloquearButton

var action_buttons: Dictionary = {}


func _ready() -> void:
	action_buttons = {
		"Abrir": abrir_button,
		"Ignorar": ignorar_button,
		"Denunciar": denunciar_button,
		"Bloquear": bloquear_button
	}

	for action in action_buttons:
		action_buttons[action].pressed.connect(_on_action_pressed.bind(action))

	danger_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	shield_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_update_hud()
	_load_current_challenge()


func _load_current_challenge() -> void:
	if current_challenge_index >= challenges.size():
		_finish_game(true)
		return

	var challenge: Dictionary = challenges[current_challenge_index]
	challenge_counter_label.text = "Desafio %d/%d" % [current_challenge_index + 1, challenges.size()]
	_type_label(challenge_text_label, String(challenge["text"]))
	_type_label(feedback_label, "Escolha a acao mais segura.")
	_set_feedback_visual(Color(0.72, 0.9, 1.0), Color(0.02, 0.08, 0.13, 0.9), Color(0.1, 0.68, 1.0, 0.65))
	_set_buttons_disabled(false)


func _on_action_pressed(action: String) -> void:
	if resolving_answer:
		return

	resolving_answer = true
	_set_buttons_disabled(true)

	var challenge: Dictionary = challenges[current_challenge_index]
	var answer_result: String = _classify_answer(challenge, action)
	var feedback_map: Dictionary = challenge["feedback_map"]
	var feedback_text: String = String(feedback_map.get(action, "Acao analisada."))

	if answer_result == "best":
		score += BEST_ANSWER_SCORE
		_type_label(feedback_label, "Resposta ideal (+%d). %s" % [BEST_ANSWER_SCORE, feedback_text])
		_set_feedback_visual(Color(0.35, 1.0, 0.58), Color(0.02, 0.14, 0.08, 0.95), Color(0.28, 1.0, 0.56, 0.9))
		hacker_visual.call("trigger_feedback", true)
		defender_visual.call("trigger_feedback", true)
		_flash_system(true)
	elif answer_result == "safe":
		score += SAFE_ANSWER_SCORE
		_type_label(feedback_label, "Resposta segura (+%d). %s" % [SAFE_ANSWER_SCORE, feedback_text])
		_set_feedback_visual(Color(0.42, 0.95, 1.0), Color(0.015, 0.1, 0.12, 0.95), Color(0.18, 0.82, 1.0, 0.9))
		hacker_visual.call("trigger_feedback", true)
		defender_visual.call("trigger_feedback", true)
		_flash_system(true)
	elif answer_result == "neutral":
		score += NEUTRAL_ANSWER_SCORE
		_type_label(feedback_label, "Resposta parcial (+%d). %s" % [NEUTRAL_ANSWER_SCORE, feedback_text])
		_set_feedback_visual(Color(1.0, 0.84, 0.3), Color(0.15, 0.1, 0.02, 0.95), Color(1.0, 0.68, 0.12, 0.9))
		hacker_visual.call("trigger_alert")
		defender_visual.call("trigger_feedback", false)
	else:
		lives -= 1
		score = max(score - UNSAFE_ANSWER_PENALTY, 0)
		threat = min(threat + THREAT_STEP, 100)
		_type_label(feedback_label, "Resposta insegura (-%d). %s" % [UNSAFE_ANSWER_PENALTY, feedback_text])
		_set_feedback_visual(Color(1.0, 0.42, 0.38), Color(0.18, 0.02, 0.04, 0.95), Color(1.0, 0.14, 0.18, 0.9))
		hacker_visual.call("trigger_feedback", false)
		defender_visual.call("trigger_feedback", false)
		_flash_system(false)

	_update_hud()
	await get_tree().create_timer(1.6).timeout

	if lives <= 0:
		_finish_game(false)
		return

	current_challenge_index += 1
	resolving_answer = false
	_load_current_challenge()
	_update_hud()


func _update_hud() -> void:
	score_label.text = "Pontuacao: %d" % score
	lives_label.text = "Vidas: %d" % lives
	threat_bar.value = threat
	_update_threat_visuals()


func _set_buttons_disabled(disabled: bool) -> void:
	for button in action_buttons.values():
		button.disabled = disabled


func _classify_answer(challenge: Dictionary, action: String) -> String:
	if action == challenge["best_answer"]:
		return "best"

	var safe_answers: Array = challenge.get("safe_answers", [])
	if safe_answers.has(action):
		return "safe"

	var neutral_answers: Array = challenge.get("neutral_answers", [])
	if neutral_answers.has(action):
		return "neutral"

	return "unsafe"


func _set_feedback_visual(font_color: Color, bg_color: Color, border_color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	feedback_panel.add_theme_stylebox_override("panel", style)
	feedback_label.add_theme_color_override("font_color", font_color)


func _type_label(label: Label, value: String) -> void:
	if label.has_method("type_text"):
		label.call("type_text", value)
	else:
		label.text = value


func _update_threat_visuals() -> void:
	var threat_ratio: float = float(threat) / 100.0
	var pulse_alpha: float = 0.16 + threat_ratio * 0.5
	threat_pulse.color = Color(1.0, 0.04, 0.08, pulse_alpha)
	security_center_mood.modulate = Color(0.9 + threat_ratio * 0.1, 1.0 - threat_ratio * 0.42, 1.0 - threat_ratio * 0.55, 0.92)
	hacker_visual.call("set_threat_level", threat_ratio)


func _flash_system(is_protected: bool) -> void:
	var overlay: ColorRect = shield_overlay
	if not is_protected:
		overlay = danger_overlay

	overlay.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.65)


func _finish_game(did_win: bool) -> void:
	GameState.set_result(score, did_win)
	get_tree().change_scene_to_file(END_SCENE)
