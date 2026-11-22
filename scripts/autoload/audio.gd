extends Node
## Toca a música e os efeitos sonoros do jogo.
## Uso: Audio.play("correct")
##
## Todos os botões do jogo tocam "click" e "hover" sozinhos, sem precisar
## ligar nada em cada cena.

const SOUNDS: Dictionary = {
	"click": preload("res://assets/audio/click.wav"),
	"hover": preload("res://assets/audio/hover.wav"),
	"type": preload("res://assets/audio/type.wav"),
	"correct": preload("res://assets/audio/correct.wav"),
	"partial": preload("res://assets/audio/partial.wav"),
	"wrong": preload("res://assets/audio/wrong.wav"),
	"lock_break": preload("res://assets/audio/lock_break.wav"),
	"window_open": preload("res://assets/audio/window_open.wav"),
	"notify": preload("res://assets/audio/notify.wav"),
	"victory": preload("res://assets/audio/victory.wav"),
	"defeat": preload("res://assets/audio/defeat.wav"),
}
const MUSIC: AudioStreamOggVorbis = preload("res://assets/audio/music.ogg")
const MUSIC_VOLUME_DB: float = -12.0
const POOL_SIZE: int = 8

var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)

	var music_stream: AudioStreamOggVorbis = MUSIC
	music_stream.loop = true
	_music = AudioStreamPlayer.new()
	_music.stream = music_stream
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)
	_music.play()

	set_enabled(GameState.sound_on)
	get_tree().node_added.connect(_on_node_added)


func play(sound: String, volume_db: float = 0.0, pitch_variation: float = 0.0) -> void:
	if not SOUNDS.has(sound):
		push_warning("Som '%s' não existe" % sound)
		return
	var player: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	player.stream = SOUNDS[sound]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


func set_enabled(enabled: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not enabled)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		button.pressed.connect(play.bind("click", -2.0, 0.05))
		button.mouse_entered.connect(func() -> void:
			if not button.disabled:
				play("hover", -8.0, 0.05))
