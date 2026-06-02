extends Control

@export var base_color: Color = Color(0.018, 0.024, 0.04, 1.0)
@export var grid_color: Color = Color(0.04, 0.55, 1.0, 0.16)
@export var pixel_color: Color = Color(0.22, 1.0, 0.68, 0.55)
@export var warning_color: Color = Color(1.0, 0.16, 0.22, 0.24)

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), base_color)
	_draw_grid()
	_draw_circuit_traces()
	_draw_pixels()
	_draw_warning_glitches()
	_draw_scanline()


func _draw_grid() -> void:
	var step: int = 32
	for x in range(0, int(size.x) + step, step):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)

	for y in range(0, int(size.y) + step, step):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)


func _draw_pixels() -> void:
	for index in range(42):
		var x: float = fposmod(float(index * 89), size.x)
		var y: float = fposmod(float(index * 53), size.y)
		var blink: float = 0.25 + 0.35 * abs(sin(_time * 1.8 + float(index)))
		var color: Color = Color(pixel_color.r, pixel_color.g, pixel_color.b, blink)
		var pixel_size: float = 3.0 + float(index % 3)
		draw_rect(Rect2(Vector2(x, y), Vector2(pixel_size, pixel_size)), color)


func _draw_circuit_traces() -> void:
	for index in range(12):
		var y: float = fposmod(float(index * 61) + _time * 8.0, size.y)
		var x: float = fposmod(float(index * 113), size.x)
		var length: float = 70.0 + float(index % 4) * 28.0
		var color: Color = Color(0.1, 0.68, 1.0, 0.18)
		draw_line(Vector2(x, y), Vector2(min(x + length, size.x), y), color, 2.0)
		draw_rect(Rect2(Vector2(x + length, y - 3.0), Vector2(6.0, 6.0)), Color(0.18, 1.0, 0.75, 0.3))


func _draw_warning_glitches() -> void:
	for index in range(8):
		var blink: float = abs(sin(_time * 2.4 + float(index)))
		if blink < 0.58:
			continue

		var x: float = fposmod(float(index * 157), size.x)
		var y: float = fposmod(float(index * 97), size.y)
		var color: Color = Color(warning_color.r, warning_color.g, warning_color.b, warning_color.a * blink)
		draw_rect(Rect2(Vector2(x, y), Vector2(22.0 + float(index % 3) * 8.0, 4.0)), color)


func _draw_scanline() -> void:
	var y: float = fposmod(_time * 80.0, size.y)
	draw_rect(Rect2(Vector2(0, y), Vector2(size.x, 2.0)), Color(0.32, 0.95, 1.0, 0.22))
