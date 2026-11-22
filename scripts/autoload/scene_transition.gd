extends CanvasLayer
## Troca de cena com um fade rápido, em vez de cortar de uma vez.
## Uso: SceneTransition.change_scene("res://scenes/game.tscn")

const FADE_TIME: float = 0.25

var _curtain: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = 100
	_curtain = ColorRect.new()
	_curtain.color = Color(0.01, 0.02, 0.035, 1.0)
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.modulate.a = 0.0
	add_child(_curtain)


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP  # bloqueia cliques durante a troca

	var fade_out: Tween = create_tween()
	fade_out.tween_property(_curtain, "modulate:a", 1.0, FADE_TIME)
	await fade_out.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	var fade_in: Tween = create_tween()
	fade_in.tween_property(_curtain, "modulate:a", 0.0, FADE_TIME)
	await fade_in.finished

	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
