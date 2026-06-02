extends Control

const GAME_SCENE: String = "res://scenes/Game.tscn"
const MENU_SCENE: String = "res://scenes/MainMenu.tscn"

@onready var result_label: Label = %ResultLabel
@onready var score_label: Label = %FinalScoreLabel
@onready var status_label: Label = %StatusLabel
@onready var status_line: ColorRect = %StatusLine
@onready var end_panel: PanelContainer = %EndPanel
@onready var background: Control = %Background
@onready var security_center_mood: TextureRect = %SecurityCenterMood
@onready var result_overlay: ColorRect = %ResultOverlay
@onready var hacker_visual: TextureRect = %HackerVisual
@onready var defender_visual: TextureRect = %DefenderVisual
@onready var play_again_button: Button = %PlayAgainButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	if GameState.victory:
		_type_label(result_label, "Vitoria! Seus dados ficaram protegidos.")
		status_label.text = "SISTEMA PROTEGIDO"
		_apply_result_visual(Color(0.03, 0.12, 0.08, 0.95), Color(0.28, 1.0, 0.56, 0.95), Color(0.47, 1.0, 0.82))
		background.set("warning_color", Color(0.12, 0.9, 0.58, 0.16))
		security_center_mood.modulate = Color(0.64, 1.0, 0.82, 0.92)
		result_overlay.color = Color(0.0, 0.04, 0.025, 0.42)
		hacker_visual.call("set_state", "defeated")
		defender_visual.call("set_state", "victory")
	else:
		_type_label(result_label, "Derrota! O hacker explorou riscos demais.")
		status_label.text = "SISTEMA COMPROMETIDO"
		_apply_result_visual(Color(0.16, 0.02, 0.04, 0.96), Color(1.0, 0.12, 0.18, 0.95), Color(1.0, 0.36, 0.32))
		background.set("grid_color", Color(1.0, 0.1, 0.18, 0.2))
		background.set("pixel_color", Color(1.0, 0.2, 0.18, 0.58))
		security_center_mood.modulate = Color(1.0, 0.32, 0.28, 0.92)
		result_overlay.color = Color(0.12, 0.0, 0.01, 0.5)
		hacker_visual.call("set_state", "attack")
		defender_visual.call("set_state", "defeat")

	_type_label(score_label, "Pontuacao final: %d" % GameState.final_score)
	play_again_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func _on_play_again_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _apply_result_visual(bg_color: Color, border_color: Color, title_color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	end_panel.add_theme_stylebox_override("panel", style)
	result_label.add_theme_color_override("font_color", title_color)
	status_label.add_theme_color_override("font_color", border_color)
	status_line.color = border_color


func _type_label(label: Label, value: String) -> void:
	if label.has_method("type_text"):
		label.call("type_text", value)
	else:
		label.text = value
