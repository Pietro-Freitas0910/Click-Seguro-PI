class_name SceneCharacter
extends TextureRect
## Personagem animado encaixado no cenário de fundo.
##
## A textura deste nó é uma MÁSCARA (branco = aparece, transparente = some).
## Com "clip_children" ligado, os quadros da animação só aparecem dentro dela,
## e as bordas suaves fazem o personagem se misturar com a imagem de fundo.

@export var sprite_frames: SpriteFrames
## Animação que fica tocando quando nada está acontecendo.
@export var rest_animation: StringName = &"idle"
## Tempo da transição suave entre um quadro e outro.
@export var crossfade_time: float = 0.12

var _animation: StringName = &""
var _frame: int = 0
var _frame_elapsed: float = 0.0
var _is_reacting: bool = false
var _reaction_id: int = 0
var _fade_tween: Tween
var _glow_tween: Tween
var _shake_tween: Tween
var _bounce_tween: Tween

@onready var _back: TextureRect = $Back
@onready var _front: TextureRect = $Front
@onready var _glow: ColorRect = $Glow


func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	pivot_offset = size / 2.0
	_glow.color.a = 0.0
	play(rest_animation)


func _process(delta: float) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(_animation):
		return

	var frame_count: int = sprite_frames.get_frame_count(_animation)
	var speed: float = sprite_frames.get_animation_speed(_animation)
	if frame_count <= 1 or speed <= 0.0:
		return

	_frame_elapsed += delta
	var frame_length: float = sprite_frames.get_frame_duration(_animation, _frame) / speed
	if _frame_elapsed < frame_length:
		return

	_frame_elapsed -= frame_length
	if _frame + 1 < frame_count:
		_show_frame(_frame + 1)
	elif sprite_frames.get_animation_loop(_animation):
		_show_frame(0)


## Troca a animação em loop.
func play(animation: StringName) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		push_warning("Animação '%s' não existe em %s" % [animation, name])
		return
	if animation == _animation:
		return
	_animation = animation
	_frame_elapsed = 0.0
	_show_frame(0)


## Muda a animação de descanso. Se não estiver reagindo, já troca.
func set_rest_animation(animation: StringName) -> void:
	rest_animation = animation
	if not _is_reacting:
		play(animation)


## Toca uma animação de reação, segura o último quadro e volta ao descanso.
## A cor ilumina o personagem rapidamente (verde = acerto, vermelho = erro).
func react(animation: StringName, hold_time: float = 1.2, color: Color = Color.TRANSPARENT) -> void:
	_reaction_id += 1
	var my_id: int = _reaction_id
	_is_reacting = true
	_animation = &""
	play(animation)
	if color.a > 0.0:
		glow(color)

	await get_tree().create_timer(_animation_length(animation) + hold_time).timeout
	if my_id != _reaction_id or not is_inside_tree():
		return
	_is_reacting = false
	play(rest_animation)


## Brilho colorido rápido por cima do personagem.
func glow(color: Color, strength: float = 0.28, duration: float = 0.7) -> void:
	if _glow_tween:
		_glow_tween.kill()
	_glow.color = Color(color.r, color.g, color.b, strength)
	_glow_tween = create_tween()
	_glow_tween.tween_property(_glow, "color:a", 0.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Treme o personagem dentro da área dele (bom para "levou um ataque").
func shake(strength: float = 8.0, duration: float = 0.35) -> void:
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.tween_method(
		func(t: float) -> void:
			var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * (1.0 - t)
			_front.position = offset
			_back.position = offset,
		0.0, 1.0, duration)
	_shake_tween.tween_callback(func() -> void:
		_front.position = Vector2.ZERO
		_back.position = Vector2.ZERO)


## Pequeno "pulo" de escala a partir do centro (bom para acertos).
func bounce(amount: float = 0.04) -> void:
	if _bounce_tween:
		_bounce_tween.kill()
	scale = Vector2.ONE
	_bounce_tween = create_tween()
	_bounce_tween.tween_property(self, "scale", Vector2.ONE * (1.0 + amount), 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(self, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _show_frame(index: int) -> void:
	_frame = index
	var frame_texture: Texture2D = sprite_frames.get_frame_texture(_animation, index)
	if frame_texture == _front.texture:
		return

	# Transição suave: o quadro antigo fica atrás e o novo aparece por cima.
	_back.texture = _front.texture
	_front.texture = frame_texture
	if _fade_tween:
		_fade_tween.kill()
	if crossfade_time <= 0.0 or _back.texture == null:
		_front.modulate.a = 1.0
		return
	_front.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_front, "modulate:a", 1.0, crossfade_time)


func _animation_length(animation: StringName) -> float:
	var speed: float = sprite_frames.get_animation_speed(animation)
	if speed <= 0.0:
		return 0.0
	var total: float = 0.0
	for i in sprite_frames.get_frame_count(animation):
		total += sprite_frames.get_frame_duration(animation, i)
	return total / speed
