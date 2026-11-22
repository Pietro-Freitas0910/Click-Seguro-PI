class_name Stage
extends Control
## O cenário completo, montado a partir da imagem de fundo:
##   Wall       -> parte de cima (parede + monitor grande), em destaque
##   LeftBooth  -> cabine do hacker (recorte do fundo + animação), menor
##   RightBooth -> cabine do jogador (recorte do fundo + animação), menor
##   Locks      -> os três cadeados que mostram as vidas
## Dentro de cada cabine as posições usam as coordenadas da imagem original,
## e a cabine inteira é reduzida (scale), então a animação fica sempre
## em cima do lugar certo do desenho.

const LOCK_OFF := Color(0.2, 0.22, 0.26, 1.0)

var _lives_shown: int = 3

@onready var hacker: SceneCharacter = $LeftBooth/Hacker
@onready var player: SceneCharacter = $RightBooth/Player
@onready var locks: Array[TextureRect] = [$Locks/Green, $Locks/Yellow, $Locks/Red]


## Mostra quantas vidas restam apagando os cadeados (verde -> amarelo -> vermelho).
func set_lives(lives: int, animated: bool = true) -> void:
	for i in locks.size():
		var is_off: bool = i < locks.size() - lives
		var was_off: bool = i < locks.size() - _lives_shown
		if is_off and not was_off and animated:
			_break_lock(locks[i])
		elif not (is_off and was_off):
			locks[i].modulate = LOCK_OFF if is_off else Color.WHITE
	_lives_shown = lives


## Deixa o cenário mais avermelhado conforme a ameaça cresce (0.0 a 1.0).
func set_threat(ratio: float, animated: bool = true) -> void:
	var mood := Color(1.0, 1.0 - ratio * 0.3, 1.0 - ratio * 0.4)
	if animated:
		create_tween().tween_property(self, "modulate", mood, 0.8)
	else:
		modulate = mood


func _break_lock(lock: TextureRect) -> void:
	lock.pivot_offset = lock.size / 2.0
	var origin: Vector2 = lock.position
	var tween: Tween = create_tween()
	tween.tween_property(lock, "modulate", Color(2.0, 2.0, 2.0), 0.08)
	for i in 6:
		var s: float = 10.0 * (1.0 - i / 6.0)
		tween.tween_property(lock, "position", origin + Vector2(randf_range(-s, s), randf_range(-s * 0.4, s * 0.4)), 0.04)
	tween.tween_property(lock, "position", origin, 0.05)
	tween.tween_property(lock, "modulate", LOCK_OFF, 0.4)
