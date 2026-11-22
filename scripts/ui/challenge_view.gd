class_name ChallengeView
extends PanelContainer
## Mostra o golpe (ou a mensagem verdadeira) como um aplicativo de verdade:
## e-mail, WhatsApp, SMS, ligação, arquivo recebido ou alerta de login.
##
## Depois que o jogador responde, reveal_clues() destaca as pistas
## (em vermelho se era golpe, ou a moldura em verde se era verdadeira).

const FONT_BOLD: FontFile = preload("res://assets/fonts/IBMPlexMono-Bold.woff2")

const CLUE_COLOR := Color(1.0, 0.3, 0.32)
const OK_COLOR := Color(0.3, 0.95, 0.55)

## Cores de cada "aplicativo".
const APPS := {
	"email": {"name": "E-mail", "bar": Color(0.16, 0.3, 0.55), "bg": Color(0.93, 0.95, 0.98), "text": Color(0.1, 0.12, 0.16)},
	"chat": {"name": "WhatsApp", "bar": Color(0.03, 0.37, 0.33), "bg": Color(0.04, 0.08, 0.1), "text": Color(0.9, 0.95, 0.95)},
	"sms": {"name": "Mensagens", "bar": Color(0.2, 0.22, 0.3), "bg": Color(0.07, 0.08, 0.11), "text": Color(0.9, 0.92, 0.96)},
	"call": {"name": "Telefone", "bar": Color(0.1, 0.14, 0.22), "bg": Color(0.05, 0.07, 0.12), "text": Color(0.9, 0.94, 1.0)},
	"file": {"name": "Mensagens", "bar": Color(0.03, 0.37, 0.33), "bg": Color(0.04, 0.08, 0.1), "text": Color(0.9, 0.95, 0.95)},
	"login": {"name": "Alerta de segurança", "bar": Color(0.55, 0.12, 0.12), "bg": Color(0.97, 0.94, 0.93), "text": Color(0.15, 0.1, 0.1)},
}

var _challenge: Dictionary = {}
var _clue_nodes: Dictionary = {}  # campo do content -> Control que mostra esse campo
var _frame_style: StyleBoxFlat
var _body: VBoxContainer
var _pulse_tween: Tween


func _ready() -> void:
	clip_contents = true
	_frame_style = StyleBoxFlat.new()
	_frame_style.set_corner_radius_all(6)
	_frame_style.set_border_width_all(2)
	_frame_style.border_color = Color(0.3, 0.45, 0.6, 0.8)
	add_theme_stylebox_override("panel", _frame_style)


## Monta a tela do aplicativo para este desafio.
func show_challenge(challenge: Dictionary) -> void:
	_challenge = challenge
	_clue_nodes.clear()
	if _pulse_tween:
		_pulse_tween.kill()
	for child in get_children():
		child.queue_free()

	var kind: String = challenge["kind"]
	var app: Dictionary = APPS[kind]
	var content: Dictionary = challenge["content"]
	_frame_style.bg_color = app["bg"]
	_frame_style.border_color = Color(0.3, 0.45, 0.6, 0.8)

	# O conteúdo fica dentro de um Control simples para não forçar a janela a
	# crescer: se a mensagem for longa demais, o final fica cortado.
	var clip := Control.new()
	clip.clip_contents = true
	add_child(clip)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	clip.add_child(root)
	root.add_child(_app_bar(app["name"], app["bar"], _app_bar_extra(kind, content)))

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	root.add_child(margin)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 5)
	margin.add_child(_body)

	match kind:
		"email": _build_email(content, app)
		"chat": _build_chat(content)
		"sms": _build_sms(content)
		"call": _build_call(content)
		"file": _build_file(content)
		"login": _build_login(content, app)

	# O aplicativo aparece com um fade rápido.
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


## Destaca as pistas depois da resposta.
func reveal_clues() -> void:
	if _challenge.get("legit", false):
		_frame_style.border_color = OK_COLOR
		_frame_style.set_border_width_all(3)
		return

	_frame_style.border_color = CLUE_COLOR
	var targets: Array[Control] = []
	for key: String in _challenge.get("clues", []):
		if _clue_nodes.has(key):
			var node: Control = _clue_nodes[key]
			_mark_clue(node)
			targets.append(node)

	# As pistas piscam algumas vezes para chamar atenção.
	_pulse_tween = create_tween().set_loops(3)
	for node in targets:
		_pulse_tween.parallel().tween_property(node, "modulate", Color(1.4, 1.4, 1.4), 0.25)
	_pulse_tween.tween_interval(0.0)
	for node in targets:
		_pulse_tween.parallel().tween_property(node, "modulate", Color.WHITE, 0.25)


## Texto corrido do desafio, para a leitura em voz alta.
func spoken_text() -> String:
	var c: Dictionary = _challenge["content"]
	match _challenge["kind"]:
		"email":
			return "E-mail de %s. Assunto: %s. %s" % [c["from_name"], c["subject"], c["body"]]
		"chat":
			return "Mensagem de %s: %s" % [c["contact"], " ".join(c["messages"])]
		"sms":
			return "SMS de %s: %s" % [c["sender"], c["text"]]
		"call":
			return "Ligação de %s. A pessoa diz: %s" % [c["caller"], c["speech"]]
		"file":
			return "%s enviou o arquivo %s e disse: %s" % [c["sender"], c["file_name"], c["message"]]
		"login":
			return "Alerta: novo acesso à sua %s, de %s, em %s, %s." % [c["service"], c["device"], c["location"], c["time"]]
	return ""


# --- Montagem de cada tipo --------------------------------------------------

func _build_email(c: Dictionary, app: Dictionary) -> void:
	var text_color: Color = app["text"]
	var from := HBoxContainer.new()
	from.add_child(_label("De: " + c["from_name"], 16, text_color, true))
	var addr := _label("<%s>" % c["from_addr"], 16, text_color.lerp(Color.GRAY, 0.4))
	from.add_child(addr)
	_body.add_child(from)
	_clue_nodes["from_addr"] = addr

	var subject := _label(c["subject"], 17, text_color, true, true)
	_body.add_child(subject)
	_clue_nodes["subject"] = subject

	var body := _label(c["body"], 16, text_color, false, true)
	_body.add_child(body)
	_clue_nodes["body"] = body

	if c.get("link", "") != "":
		var link := _label(c["link"], 16, Color(0.1, 0.35, 0.85), true)
		link.add_theme_constant_override("outline_size", 0)
		_body.add_child(link)
		_clue_nodes["link"] = link


func _build_chat(c: Dictionary) -> void:
	var bubbles := VBoxContainer.new()
	bubbles.add_theme_constant_override("separation", 6)
	for message: String in c["messages"]:
		bubbles.add_child(_bubble(message, Color(0.12, 0.17, 0.2)))
	_body.add_child(bubbles)
	_clue_nodes["messages"] = bubbles


func _build_sms(c: Dictionary) -> void:
	var bubble := _bubble(c["text"], Color(0.16, 0.18, 0.26))
	_body.add_child(bubble)
	_clue_nodes["text"] = bubble


func _build_call(c: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_avatar(c["caller"].substr(0, 1), Color(0.25, 0.4, 0.7), 52))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.add_child(_label(c["caller"], 20, Color.WHITE, true))
	info.add_child(_label(c["number"] + "   chamando...", 15, Color(0.6, 0.75, 0.9)))
	row.add_child(info)
	_body.add_child(row)

	_body.add_child(_label("Ao atender, a pessoa diz:", 14, Color(0.55, 0.65, 0.8)))
	var speech := _bubble("\"%s\"" % c["speech"], Color(0.13, 0.17, 0.26))
	_body.add_child(speech)
	_clue_nodes["speech"] = speech


func _build_file(c: Dictionary) -> void:
	_body.add_child(_bubble(c["message"], Color(0.12, 0.17, 0.2)))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _box(Color(0.1, 0.14, 0.18), 6, Color(0.3, 0.4, 0.45)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var badge := _avatar(c["file_name"].get_extension().to_upper(), Color(0.45, 0.47, 0.52), 38, 11)
	row.add_child(badge)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	var name_label := _label(c["file_name"], 17, Color.WHITE, true)
	info.add_child(name_label)
	info.add_child(_label(c["file_size"] + "  -  toque para abrir", 14, Color(0.6, 0.7, 0.75)))
	row.add_child(info)
	card.add_child(_padded(row, 6))
	_body.add_child(card)
	_clue_nodes["file_name"] = name_label


func _build_login(c: Dictionary, app: Dictionary) -> void:
	var text_color: Color = app["text"]
	_body.add_child(_label("Novo acesso à sua %s" % c["service"], 18, text_color, true))
	_body.add_child(_label("Foi você? Se não reconhece, proteja sua conta.", 15, text_color.lerp(Color.GRAY, 0.4)))
	for key: String in ["device", "location", "time"]:
		var titles := {"device": "Aparelho", "location": "Local", "time": "Quando"}
		var row := HBoxContainer.new()
		var title := _label(titles[key] + ":", 16, text_color.lerp(Color.GRAY, 0.4))
		title.custom_minimum_size.x = 120
		row.add_child(title)
		var value := _label(c[key], 16, text_color, true)
		row.add_child(value)
		_body.add_child(row)
		_clue_nodes[key] = value


# --- Peças reutilizáveis -----------------------------------------------------

func _app_bar(app_name: String, color: Color, extra: String) -> PanelContainer:
	var bar := PanelContainer.new()
	var style := _box(color, 0)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	bar.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	var title := _label(app_name, 15, Color.WHITE, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var right := _label(extra, 15, Color(1, 1, 1, 0.85), true)
	row.add_child(right)
	if _challenge.get("kind") in ["chat", "file", "sms"]:
		_clue_nodes["contact"] = right
		_clue_nodes["sender"] = right
	bar.add_child(_padded(row, 4, 10))
	return bar


func _app_bar_extra(kind: String, c: Dictionary) -> String:
	match kind:
		"chat": return c["contact"]
		"file": return c["sender"]
		"sms": return "De: " + c["sender"]
		"call": return "Ligação recebida"
		"email": return "Caixa de entrada"
	return ""


func _bubble(text: String, color: Color) -> Control:
	var row := HBoxContainer.new()
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.size_flags_stretch_ratio = 5.0
	bubble.add_theme_stylebox_override("panel", _box(color, 8))
	bubble.add_child(_padded(_label(text, 16, Color(0.92, 0.95, 0.96), false, true), 6, 10))
	row.add_child(bubble)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	return row


func _avatar(letter: String, color: Color, size_px: int, font_size: int = 20) -> PanelContainer:
	var circle := PanelContainer.new()
	circle.custom_minimum_size = Vector2(size_px, size_px)
	circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	circle.add_theme_stylebox_override("panel", _box(color, int(size_px / 2.0)))
	var label := _label(letter, font_size, Color.WHITE, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	circle.add_child(label)
	return circle


func _label(text: String, font_size: int, color: Color, bold: bool = false, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", FONT_BOLD)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _box(color: Color, radius: int, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if border.a > 0.0:
		style.border_color = border
		style.set_border_width_all(1)
	return style


func _padded(child: Control, vertical: int, horizontal: int = -1) -> MarginContainer:
	if horizontal < 0:
		horizontal = vertical
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)
	margin.add_child(child)
	return margin


## Marca uma pista: texto em vermelho ou balão com borda vermelha.
func _mark_clue(node: Control) -> void:
	if node is Label:
		(node as Label).add_theme_color_override("font_color", CLUE_COLOR)
		return
	for panel in node.find_children("*", "PanelContainer", true, false):
		var style: StyleBoxFlat = (panel as PanelContainer).get_theme_stylebox("panel").duplicate()
		style.border_color = CLUE_COLOR
		style.set_border_width_all(2)
		(panel as PanelContainer).add_theme_stylebox_override("panel", style)
