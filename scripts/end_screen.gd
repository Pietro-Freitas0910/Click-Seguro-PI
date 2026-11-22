extends Control
## Relatório final: resultado, recorde e o que aprender com cada desafio.

const GAME_SCENE: String = "res://scenes/game.tscn"
const MENU_SCENE: String = "res://scenes/main_menu.tscn"

const COLOR_WIN := Color(0.3, 1.0, 0.56)
const COLOR_LOSE := Color(1.0, 0.25, 0.3)
const RESULT_INFO := {
	"best": {"mark": "ACERTOU", "color": Color(0.3, 1.0, 0.56)},
	"safe": {"mark": "SEGURO", "color": Color(0.35, 0.9, 1.0)},
	"neutral": {"mark": "PARCIAL", "color": Color(1.0, 0.78, 0.25)},
	"unsafe": {"mark": "ERROU", "color": Color(1.0, 0.3, 0.32)},
}
## Erros aparecem primeiro no relatório.
const ORDER := {"unsafe": 0, "neutral": 1, "safe": 2, "best": 3}

@onready var window: Control = %Window
@onready var body: PanelContainer = %Body
@onready var status_label: Label = %StatusLabel
@onready var status_line: ColorRect = %StatusLine
@onready var result_label: TypewriterLabel = %ResultLabel
@onready var score_label: Label = %FinalScoreLabel
@onready var review_list: VBoxContainer = %ReviewList
@onready var stage: Stage = %Stage
@onready var action_frame: Control = %ActionFrame
@onready var play_again_button: Button = %PlayAgainButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	play_again_button.pressed.connect(SceneTransition.change_scene.bind(GAME_SCENE))
	menu_button.pressed.connect(SceneTransition.change_scene.bind(MENU_SCENE))

	if GameState.victory:
		_show_result("SISTEMA PROTEGIDO", "Vitória! Seus dados ficaram protegidos.", COLOR_WIN)
		stage.hacker.play(&"defeated")
		stage.player.play(&"victory")
		stage.player.glow(COLOR_WIN, 0.3, 1.2)
		Audio.play("victory", -2.0)
	else:
		_show_result("SISTEMA COMPROMETIDO", "Derrota! O hacker invadiu o computador.", COLOR_LOSE)
		stage.set_threat(1.0, false)
		stage.set_lives(0, false)
		stage.hacker.play(&"victorious")
		stage.player.play(&"defeat")
		stage.hacker.glow(COLOR_LOSE, 0.3, 1.2)
		Audio.play("defeat", -2.0)

	var record_text: String = "NOVO RECORDE!" if GameState.new_record else "Recorde: %d" % GameState.best_score
	score_label.text = "Pontuação: %d  |  %s" % [GameState.final_score, record_text]
	if GameState.new_record:
		score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

	_build_review()
	play_again_button.grab_focus()
	_play_intro()


func _show_result(status: String, message: String, color: Color) -> void:
	status_label.text = status
	status_label.add_theme_color_override("font_color", color)
	status_line.color = color
	result_label.add_theme_color_override("font_color", color.lightened(0.3))
	result_label.type_text(message)

	var style: StyleBoxFlat = body.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color(color.darkened(0.9), 0.94)
	body.add_theme_stylebox_override("panel", style)


## Monta a lista com o que o jogador escolheu e a dica de cada situação.
func _build_review() -> void:
	var answers: Array[Dictionary] = GameState.answers.duplicate()
	answers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return ORDER[a["result"]] < ORDER[b["result"]])

	for answer: Dictionary in answers:
		var challenge: Dictionary = answer["challenge"]
		var info: Dictionary = RESULT_INFO[answer["result"]]
		var color: Color = info["color"]

		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(color.darkened(0.85), 0.9)
		style.border_color = color
		style.border_width_left = 4
		style.set_corner_radius_all(4)
		style.content_margin_left = 12
		style.content_margin_right = 10
		style.content_margin_top = 5
		style.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", style)

		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		var head := Label.new()
		head.text = "[%s]  %s  -  você escolheu: %s" % [
			info["mark"], challenge["title"], Challenges.label_for(challenge, answer["action"])]
		head.add_theme_color_override("font_color", color.lightened(0.2))
		head.add_theme_font_size_override("font_size", 16)
		head.add_theme_font_override("font", ChallengeView.FONT_BOLD)
		column.add_child(head)
		var tip := Label.new()
		tip.text = challenge["tip"]
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tip.add_theme_font_size_override("font_size", 16)
		column.add_child(tip)
		card.add_child(column)
		review_list.add_child(card)


func _play_intro() -> void:
	window.pivot_offset = window.size / 2.0
	window.scale = Vector2(0.9, 0.9)
	window.modulate.a = 0.0
	action_frame.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(window, "modulate:a", 1.0, 0.25).set_delay(0.2)
	tween.parallel().tween_property(window, "scale", Vector2.ONE, 0.35).set_delay(0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(action_frame, "modulate:a", 1.0, 0.3)
