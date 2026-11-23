extends Control
## Relatório final: resultado, recorde, o que aprender com cada desafio,
## histórico de impacto e certificado de participação.

const GAME_SCENE: String = "res://scenes/game.tscn"
const MENU_SCENE: String = "res://scenes/main_menu.tscn"

const COLOR_WIN := Color(0.3, 1.0, 0.56)
const COLOR_LOSE := Color(1.0, 0.25, 0.3)
const COLOR_HISTORY := Color(0.35, 0.85, 1.0)
const RESULT_INFO := {
	"best": {"mark": "ACERTOU", "color": Color(0.3, 1.0, 0.56)},
	"safe": {"mark": "SEGURO", "color": Color(0.35, 0.9, 1.0)},
	"neutral": {"mark": "PARCIAL", "color": Color(1.0, 0.78, 0.25)},
	"unsafe": {"mark": "ERROU", "color": Color(1.0, 0.3, 0.32)},
}
## Erros aparecem primeiro no relatório.
const ORDER := {"unsafe": 0, "neutral": 1, "safe": 2, "best": 3}
const REVIEW_FONT_SIZE: int = 16

const PAPER_COLOR := Color(0.98, 0.96, 0.88)
const PAPER_BORDER := Color(0.75, 0.6, 0.25)
const INK_COLOR := Color(0.16, 0.13, 0.08)

@onready var screen: Control = $Screen
@onready var screen_flash: ColorRect = %ScreenFlash
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
@onready var certificate_button: Button = %CertificateButton
@onready var menu_button: Button = %MenuButton

var _certificate: Control
var _name_edit: LineEdit
var _certificate_text: Label
## No navegador do celular o teclado do Godot nem sempre abre, então lá o nome
## é pedido pela caixa de texto do próprio navegador (que abre o teclado).
var _use_browser_prompt: bool = OS.has_feature("web_android") or OS.has_feature("web_ios")


func _ready() -> void:
	play_again_button.pressed.connect(SceneTransition.change_scene.bind(GAME_SCENE))
	menu_button.pressed.connect(SceneTransition.change_scene.bind(MENU_SCENE))
	certificate_button.pressed.connect(_open_certificate)

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
	_build_history()
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
		var head_text: String = "[%s]  %s  -  você escolheu: %s" % [
			info["mark"], challenge["title"], Challenges.label_for(challenge, answer["action"])]
		review_list.add_child(_card(color, head_text, challenge["tip"]))


## Histórico de todas as partidas: serve de "contador de impacto".
func _build_history() -> void:
	if GameState.answers_total == 0:
		return
	var parts := PackedStringArray()
	for kind: String in Challenges.KIND_NAMES:
		if GameState.kind_stats.has(kind):
			var stat: Array = GameState.kind_stats[kind]
			parts.append("%s %d/%d" % [Challenges.KIND_NAMES[kind], int(stat[0]), int(stat[1])])
	var head_text: String = "[SEU HISTÓRICO]  %d partidas  -  %d de %d golpes identificados" % [
		GameState.games_played, GameState.scams_spotted, GameState.scams_seen]
	review_list.add_child(_card(COLOR_HISTORY, head_text, "Respostas seguras por tipo: " + ", ".join(parts)))


func _card(color: Color, head_text: String, body_text: String) -> PanelContainer:
	var font_size: int = roundi(REVIEW_FONT_SIZE * GameState.text_scale())
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
	head.text = head_text
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_theme_color_override("font_color", color.lightened(0.2))
	head.add_theme_font_size_override("font_size", font_size)
	head.add_theme_font_override("font", ChallengeView.FONT_BOLD)
	column.add_child(head)
	var tip := Label.new()
	tip.text = body_text
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", font_size)
	column.add_child(tip)
	card.add_child(column)
	return card


# --- Certificado ----------------------------------------------------------------

func _open_certificate() -> void:
	if _certificate == null:
		_build_certificate()
	_name_edit.text = GameState.player_name
	_update_certificate_text()
	_certificate.visible = true
	_certificate.modulate.a = 0.0
	create_tween().tween_property(_certificate, "modulate:a", 1.0, 0.25)
	if not _use_browser_prompt:
		_name_edit.grab_focus()


func _close_certificate() -> void:
	GameState.set_player_name(_name_edit.text)
	var tween: Tween = create_tween()
	tween.tween_property(_certificate, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void: _certificate.visible = false)
	certificate_button.grab_focus()


func _update_certificate_text(_new_text: String = "") -> void:
	var player_name: String = _name_edit.text.strip_edges()
	if player_name == "":
		player_name = "__________"
	var date: Dictionary = Time.get_date_dict_from_system()
	_certificate_text.text = "Certificamos que %s participou do treinamento Click Seguro em %02d/%02d/%04d e respondeu com segurança a %d de %d situações de possíveis golpes digitais." % [
		player_name, date["day"], date["month"], date["year"],
		GameState.run_safe_count(), GameState.answers.size()]


## O certificado é montado por código, como uma folha por cima da tela do computador.
func _build_certificate() -> void:
	_certificate = Control.new()
	_certificate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(_certificate)
	# Fica abaixo do flash e do efeito de monitor, como o resto da interface.
	screen.move_child(_certificate, screen_flash.get_index())

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.01, 0.03, 0.8)
	_certificate.add_child(shade)

	var panel := PanelContainer.new()
	panel.theme_type_variation = &"WindowBody"
	panel.anchor_left = 0.06
	panel.anchor_right = 0.94
	panel.anchor_top = 0.04
	panel.anchor_bottom = 0.96
	_certificate.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	# Nome do jogador.
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	var name_title := Label.new()
	name_title.text = "Seu nome:"
	name_title.add_theme_font_size_override("font_size", 17)
	name_row.add_child(name_title)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Digite seu nome para o certificado"
	_name_edit.max_length = 40
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.add_theme_font_size_override("font_size", 18)
	_name_edit.text_changed.connect(_update_certificate_text)
	_name_edit.text_submitted.connect(func(_text: String) -> void: _name_edit.release_focus())
	if _use_browser_prompt:
		_name_edit.editable = false
		_name_edit.placeholder_text = "Toque aqui para digitar seu nome"
		_name_edit.gui_input.connect(_on_name_input)
	name_row.add_child(_name_edit)
	column.add_child(name_row)

	# A "folha" do certificado.
	var paper := PanelContainer.new()
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = PAPER_COLOR
	paper_style.border_color = PAPER_BORDER
	paper_style.set_border_width_all(4)
	paper_style.set_corner_radius_all(6)
	paper_style.content_margin_left = 24
	paper_style.content_margin_right = 24
	paper_style.content_margin_top = 10
	paper_style.content_margin_bottom = 10
	paper.add_theme_stylebox_override("panel", paper_style)
	var sheet := VBoxContainer.new()
	sheet.alignment = BoxContainer.ALIGNMENT_CENTER
	sheet.add_theme_constant_override("separation", 8)
	paper.add_child(sheet)
	column.add_child(paper)

	var title := _paper_label("CERTIFICADO", 34, PAPER_BORDER.darkened(0.45))
	title.theme_type_variation = &"HeaderLabel"
	title.add_theme_constant_override("outline_size", 0)
	sheet.add_child(title)
	sheet.add_child(_paper_label("Click Seguro  -  Treinamento contra golpes digitais", 16, INK_COLOR.lightened(0.3)))
	_certificate_text = _paper_label("", 18, INK_COLOR)
	sheet.add_child(_certificate_text)
	sheet.add_child(_paper_label("Ao todo neste aparelho: %d partidas e %d golpes identificados." % [
		GameState.games_played, GameState.scams_spotted], 14, INK_COLOR.lightened(0.35)))
	sheet.add_child(_paper_label("Projeto de Extensão  -  UniFil  -  Engenharia de Software", 14, INK_COLOR.lightened(0.35)))

	# Rodapé com a dica e o botão de fechar.
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	var hint := Label.new()
	hint.text = "Dica: tire um print da tela para guardar o certificado."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	bottom.add_child(hint)
	var close_button := Button.new()
	close_button.text = "FECHAR"
	close_button.custom_minimum_size = Vector2(180, 40)
	close_button.add_theme_font_size_override("font_size", 19)
	close_button.pressed.connect(_close_certificate)
	bottom.add_child(close_button)
	column.add_child(bottom)


## Celular: tocar no campo abre a caixa de texto do navegador.
func _on_name_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	# Reage ao soltar o dedo: a caixa do navegador pausa o jogo enquanto está aberta.
	if mouse and mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
		_ask_name_in_browser()


func _ask_name_in_browser() -> void:
	var script: String = "prompt('Digite seu nome para o certificado:', %s)" % JSON.stringify(_name_edit.text)
	var answer: Variant = JavaScriptBridge.eval(script, true)
	if typeof(answer) == TYPE_STRING:  # null = a pessoa cancelou
		_name_edit.text = (answer as String).strip_edges().left(_name_edit.max_length)
		_update_certificate_text()


func _paper_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


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
