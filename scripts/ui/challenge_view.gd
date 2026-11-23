class_name ChallengeView
extends PanelContainer
## Mostra o golpe (ou a mensagem verdadeira) como um aplicativo de verdade:
## e-mail, mensagens, SMS, ligação, arquivo recebido, alerta de login,
## QR Code em um cartaz ou boleto.
##
## Depois que o jogador responde, reveal_clues() destaca as pistas e coloca
## uma etiqueta explicando cada uma (vermelha se era golpe, verde se era
## mensagem verdadeira). Se o conteúdo não couber, dá para rolar.

const FONT_BOLD: FontFile = preload("res://assets/fonts/IBMPlexMono-Bold.woff2")

const CLUE_COLOR := Color(1.0, 0.3, 0.32)
const OK_COLOR := Color(0.3, 0.95, 0.55)
const QR_CELLS: int = 21
const QR_CELL_PX: int = 5

## Cores de cada "aplicativo".
const APPS := {
	"email": {"name": "E-mail", "bar": Color(0.16, 0.3, 0.55), "bg": Color(0.93, 0.95, 0.98), "text": Color(0.1, 0.12, 0.16)},
	"chat": {"name": "Mensageiro", "bar": Color(0.03, 0.37, 0.33), "bg": Color(0.04, 0.08, 0.1), "text": Color(0.9, 0.95, 0.95)},
	"sms": {"name": "SMS", "bar": Color(0.2, 0.22, 0.3), "bg": Color(0.07, 0.08, 0.11), "text": Color(0.9, 0.92, 0.96)},
	"call": {"name": "Telefone", "bar": Color(0.1, 0.14, 0.22), "bg": Color(0.05, 0.07, 0.12), "text": Color(0.9, 0.94, 1.0)},
	"file": {"name": "Mensageiro", "bar": Color(0.03, 0.37, 0.33), "bg": Color(0.04, 0.08, 0.1), "text": Color(0.9, 0.95, 0.95)},
	"login": {"name": "Alerta de segurança", "bar": Color(0.55, 0.12, 0.12), "bg": Color(0.97, 0.94, 0.93), "text": Color(0.15, 0.1, 0.1)},
	"qr": {"name": "Câmera", "bar": Color(0.12, 0.12, 0.14), "bg": Color(0.06, 0.07, 0.09), "text": Color(0.9, 0.92, 0.95)},
	"boleto": {"name": "Boleto", "bar": Color(0.22, 0.32, 0.22), "bg": Color(0.97, 0.96, 0.91), "text": Color(0.12, 0.12, 0.1)},
}

var _challenge: Dictionary = {}
var _clue_nodes: Dictionary = {}  # campo do content -> Control que mostra esse campo
var _frame_style: StyleBoxFlat
var _scroll: ScrollContainer
var _body: VBoxContainer
var _more_hint: Label
var _pulse_tween: Tween
var _revealed: bool = false
## Tamanho das letras (1.0 normal, maior com a opção "Letra grande").
var _scale: float = 1.0


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
	_revealed = false
	_scale = GameState.text_scale()
	if _pulse_tween:
		_pulse_tween.kill()
	for child in get_children():
		child.queue_free()

	var kind: String = challenge["kind"]
	var app: Dictionary = APPS[kind]
	var content: Dictionary = challenge["content"]
	_frame_style.bg_color = app["bg"]
	_frame_style.border_color = Color(0.3, 0.45, 0.6, 0.8)
	_frame_style.set_border_width_all(2)

	# O conteúdo fica dentro de uma rolagem: se a mensagem for longa (ou a
	# letra estiver grande), dá para rolar em vez de cortar o final.
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 0)
	_scroll.add_child(root)
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
		"qr": _build_qr(content, app)
		"boleto": _build_boleto(content, app)

	_let_scroll_through(root)
	_add_more_hint()

	# O aplicativo aparece com um fade rápido.
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


## Destaca as pistas depois da resposta, cada uma com a explicação ao lado.
func reveal_clues() -> void:
	_revealed = true
	var legit: bool = _challenge.get("legit", false)
	_frame_style.border_color = OK_COLOR if legit else CLUE_COLOR
	_frame_style.set_border_width_all(3 if legit else 2)

	var clues: Dictionary = _challenge.get("clues", {})
	var targets: Array[Control] = []
	var tags: Array[Control] = []
	var last_tag_after: Dictionary = {}  # linha do corpo -> última etiqueta posta depois dela
	var top_count: int = 0
	for key: String in clues:
		if not _clue_nodes.has(key):
			continue
		var node: Control = _clue_nodes[key]
		if not legit:
			_mark_clue(node)
			targets.append(node)

		var tag: Control = _clue_tag(clues[key], legit)
		_body.add_child(tag)
		var row: Control = _row_in_body(node)
		if row == null:
			# Pista na barra do aplicativo (contato/remetente): etiqueta no topo.
			_body.move_child(tag, top_count)
			top_count += 1
		else:
			var anchor: Control = last_tag_after.get(row, row)
			_body.move_child(tag, anchor.get_index() + 1)
			last_tag_after[row] = tag
		tags.append(tag)

	for i in tags.size():
		tags[i].modulate.a = 0.0
		create_tween().tween_property(tags[i], "modulate:a", 1.0, 0.3).set_delay(0.12 * i)

	# As pistas piscam algumas vezes para chamar atenção.
	if not targets.is_empty():
		_pulse_tween = create_tween().set_loops(3)
		for node in targets:
			_pulse_tween.parallel().tween_property(node, "modulate", Color(1.4, 1.4, 1.4), 0.25)
		_pulse_tween.tween_interval(0.0)
		for node in targets:
			_pulse_tween.parallel().tween_property(node, "modulate", Color.WHITE, 0.25)

	# Espera o layout encaixar as etiquetas e rola até a primeira delas.
	if tags.is_empty():
		return
	var scroll: ScrollContainer = _scroll
	var first_tag: Control = tags[0]
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(scroll) and is_instance_valid(first_tag) and first_tag.is_inside_tree():
		scroll.ensure_control_visible(first_tag)
	_update_more_hint()


## Texto corrido do desafio, para a leitura em voz alta.
## Depois da resposta, também lê a explicação das pistas.
func spoken_text() -> String:
	var text: String = _content_text()
	if _revealed:
		var reasons: Array = _challenge.get("clues", {}).values()
		if not reasons.is_empty():
			var title: String = "Por que é confiável: " if _challenge.get("legit", false) else "Pistas: "
			text += " " + title + " ".join(reasons)
	return text


func _content_text() -> String:
	var c: Dictionary = _challenge["content"]
	match _challenge["kind"]:
		"email":
			return "E-mail de %s, endereço %s. Assunto: %s. %s" % [c["from_name"], c["from_addr"], c["subject"], c["body"]]
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
		"qr":
			return "Cartaz: %s. %s %s Ao apontar a câmera, aparece o site %s. %s." % [c["title"], c["subtitle"], c["note"], c["link"], c["receiver"]]
		"boleto":
			return "Boleto. %s. Beneficiário: %s. Valor: %s. Vencimento: %s." % [c["origin"], c["beneficiary"], c["amount"], c["due"]]
	return ""


# --- Montagem de cada tipo --------------------------------------------------

func _build_email(c: Dictionary, app: Dictionary) -> void:
	var text_color: Color = app["text"]
	# HFlowContainer quebra a linha se o nome + endereço não couberem.
	var from := HFlowContainer.new()
	from.add_theme_constant_override("h_separation", 8)
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
		var link := _url_label(c["link"], 16, Color(0.1, 0.35, 0.85))
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
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	info.add_child(_label(c["caller"], 20, Color.WHITE, true, true))
	info.add_child(_label(c["number"] + "   chamando...", 15, Color(0.6, 0.75, 0.9), false, true))
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
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	var name_label := _label(c["file_name"], 17, Color.WHITE, true)
	info.add_child(name_label)
	info.add_child(_label(c["file_size"] + "  -  toque para abrir", 14, Color(0.6, 0.7, 0.75), false, true))
	row.add_child(info)
	card.add_child(_padded(row, 6))
	_body.add_child(card)
	_clue_nodes["file_name"] = name_label


func _build_login(c: Dictionary, app: Dictionary) -> void:
	var text_color: Color = app["text"]
	_body.add_child(_label("Novo acesso à sua %s" % c["service"], 18, text_color, true, true))
	_body.add_child(_label("Foi você? Se não reconhece, proteja sua conta.", 15, text_color.lerp(Color.GRAY, 0.4), false, true))
	var titles := {"device": "Aparelho", "location": "Local", "time": "Quando"}
	for key: String in ["device", "location", "time"]:
		_body.add_child(_field_row(titles[key], c[key], key, text_color))


## Cartaz com QR Code. Mostra o que aparece ao apontar a câmera.
func _build_qr(c: Dictionary, app: Dictionary) -> void:
	var dark := Color(0.12, 0.12, 0.14)
	var poster := PanelContainer.new()
	var poster_style := _box(Color(0.96, 0.93, 0.82), 6)
	poster_style.content_margin_left = 10
	poster_style.content_margin_right = 10
	poster_style.content_margin_top = 8
	poster_style.content_margin_bottom = 8
	poster.add_theme_stylebox_override("panel", poster_style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.add_child(_qr_code(c["link"]))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	info.add_child(_label(c["title"], 18, dark, true, true))
	info.add_child(_label(c["subtitle"], 16, dark, false, true))
	var note := _label(c["note"], 14, Color(0.45, 0.3, 0.08), false, true)
	info.add_child(note)
	row.add_child(info)
	poster.add_child(row)
	_body.add_child(poster)
	_clue_nodes["note"] = note

	var text_color: Color = app["text"]
	_body.add_child(_label("Ao apontar a câmera, o celular mostra:", 14, text_color.lerp(Color.GRAY, 0.4), false, true))
	var link := _url_label(c["link"], 16, Color(0.45, 0.75, 1.0))
	_body.add_child(link)
	_clue_nodes["link"] = link
	var receiver := _label(c["receiver"], 15, text_color, true, true)
	_body.add_child(receiver)
	_clue_nodes["receiver"] = receiver


## Boleto de pagamento: de onde veio, quem recebe, valor e vencimento.
func _build_boleto(c: Dictionary, app: Dictionary) -> void:
	var text_color: Color = app["text"]
	var origin := _label(c["origin"], 14, text_color.lerp(Color.GRAY, 0.35), false, true)
	_body.add_child(origin)
	_clue_nodes["origin"] = origin
	var titles := {"beneficiary": "Beneficiário", "amount": "Valor", "due": "Vencimento"}
	for key: String in ["beneficiary", "amount", "due"]:
		_body.add_child(_field_row(titles[key], c[key], key, text_color))
	_body.add_child(_barcode(c["barcode"]))
	var digits := _label(c["barcode"], 13, text_color.lerp(Color.GRAY, 0.4))
	digits.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_body.add_child(digits)


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
		"qr": return "Leitor de QR Code"
		"boleto": return "Documento"
	return ""


## Linha "Título: valor", usada no alerta de login e no boleto.
func _field_row(title_text: String, value_text: String, key: String, text_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var title := _label(title_text + ":", 16, text_color.lerp(Color.GRAY, 0.4))
	title.custom_minimum_size.x = roundi(130 * _scale)
	row.add_child(title)
	var value := _label(value_text, 16, text_color, true, true)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)
	_clue_nodes[key] = value
	return row


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


## QR Code de enfeite (não é lido de verdade), sempre igual para o mesmo link.
func _qr_code(seed_text: String) -> Control:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	var holder := PanelContainer.new()
	var style := _box(Color.WHITE, 2)
	style.set_content_margin_all(5)
	holder.add_theme_stylebox_override("panel", style)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var grid := GridContainer.new()
	grid.columns = QR_CELLS
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	for y in QR_CELLS:
		for x in QR_CELLS:
			var cell := ColorRect.new()
			cell.custom_minimum_size = Vector2(QR_CELL_PX, QR_CELL_PX)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.color = Color.BLACK if _qr_is_dark(x, y, rng) else Color.WHITE
			grid.add_child(cell)
	holder.add_child(grid)
	return holder


## Os três quadrados dos cantos são o "desenho" típico de um QR Code.
func _qr_is_dark(x: int, y: int, rng: RandomNumberGenerator) -> bool:
	var last: int = QR_CELLS - 7
	for corner: Vector2i in [Vector2i(0, 0), Vector2i(last, 0), Vector2i(0, last)]:
		var lx: int = x - corner.x
		var ly: int = y - corner.y
		if lx >= -1 and lx <= 7 and ly >= -1 and ly <= 7:
			if lx < 0 or lx > 6 or ly < 0 or ly > 6:
				return false  # margem branca em volta do quadrado
			var ring: int = maxi(absi(lx - 3), absi(ly - 3))
			return ring == 3 or ring <= 1
	return rng.randf() < 0.5


## Código de barras de enfeite, sempre igual para os mesmos números.
func _barcode(seed_text: String) -> Control:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	var holder := PanelContainer.new()
	var style := _box(Color.WHITE, 0)
	style.set_content_margin_all(4)
	holder.add_theme_stylebox_override("panel", style)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var bars := HBoxContainer.new()
	bars.add_theme_constant_override("separation", 0)
	for i in 70:
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(rng.randi_range(1, 3), 30)
		bar.color = Color.BLACK if i % 2 == 0 else Color.WHITE
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bars.add_child(bar)
	holder.add_child(bars)
	return holder


func _label(text: String, font_size: int, color: Color, bold: bool = false, wraps: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(font_size * _scale))
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", FONT_BOLD)
	if wraps:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## Endereço de site: pode quebrar em qualquer letra, porque não tem espaços.
func _url_label(url: String, font_size: int, color: Color) -> Label:
	var label := _label(url, font_size, color, true)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.add_theme_constant_override("outline_size", 0)
	return label


## Etiqueta com a explicação de uma pista.
func _clue_tag(reason: String, legit: bool) -> Control:
	var color: Color = OK_COLOR if legit else CLUE_COLOR
	var tag := PanelContainer.new()
	var style := _box(color.darkened(0.6), 4, color)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 3
	tag.add_theme_stylebox_override("panel", style)
	tag.mouse_filter = Control.MOUSE_FILTER_PASS
	var prefix: String = "SEGURO: " if legit else "PISTA: "
	tag.add_child(_label(prefix + reason, 14, Color.WHITE, true, true))
	return tag


## Aviso "tem mais abaixo", que aparece quando a mensagem não cabe toda.
func _add_more_hint() -> void:
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	_more_hint = _label("Tem mais abaixo: role a mensagem", 13, Color.WHITE, true)
	_more_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_more_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var style := _box(Color(0.05, 0.12, 0.22, 0.92), 4, Color(0.35, 0.85, 1.0))
	_more_hint.add_theme_stylebox_override("normal", style)
	_more_hint.anchor_left = 0.0
	_more_hint.anchor_right = 1.0
	_more_hint.anchor_top = 1.0
	_more_hint.anchor_bottom = 1.0
	_more_hint.offset_left = 30
	_more_hint.offset_right = -30
	_more_hint.offset_top = -roundi(26 * _scale) - 4
	_more_hint.offset_bottom = -4
	_more_hint.visible = false
	layer.add_child(_more_hint)
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	bar.changed.connect(_update_more_hint)
	bar.value_changed.connect(func(_value: float) -> void: _update_more_hint())


func _update_more_hint() -> void:
	if not is_instance_valid(_scroll) or not is_instance_valid(_more_hint):
		return
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	_more_hint.visible = bar.max_value - bar.page - bar.value > 6.0


## Painéis normalmente "seguram" o mouse; aqui eles deixam passar, para a
## rodinha do mouse e o arrastar com o dedo rolarem a mensagem.
func _let_scroll_through(node: Control) -> void:
	if node.mouse_filter == Control.MOUSE_FILTER_STOP:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in node.find_children("*", "Control", true, false):
		var control := child as Control
		if control.mouse_filter == Control.MOUSE_FILTER_STOP:
			control.mouse_filter = Control.MOUSE_FILTER_PASS


## Sobe da pista até achar a linha que é filha direta do corpo da mensagem.
func _row_in_body(node: Node) -> Control:
	var current: Node = node
	while current != null and current != self:
		if current.get_parent() == _body:
			return current as Control
		current = current.get_parent()
	return null


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
