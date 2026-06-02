extends Control

@export var scanline_color: Color = Color(0.0, 0.0, 0.0, 0.18)
@export var glow_color: Color = Color(0.12, 0.8, 1.0, 0.08)

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var y: int = 0
	while y < int(size.y):
		draw_rect(Rect2(Vector2(0.0, float(y)), Vector2(size.x, 1.0)), scanline_color)
		y += 4

	var sweep_y: float = fposmod(_time * 48.0, size.y)
	draw_rect(Rect2(Vector2(0.0, sweep_y), Vector2(size.x, 3.0)), glow_color)
