extends Node
## Guarda o resultado da partida e as preferências do jogador.
## O recorde e as opções ficam salvos no navegador (user://).

const SAVE_PATH: String = "user://click_seguro.cfg"

# Resultado da última partida (usado pela tela final).
var final_score: int = 0
var victory: bool = false
## Cada item: {"challenge": Dictionary, "action": String, "result": String}
var answers: Array[Dictionary] = []

# Salvo entre partidas.
var best_score: int = 0
var new_record: bool = false
var sound_on: bool = true
var tutorial_seen: bool = false


func _ready() -> void:
	_load()


func start_run() -> void:
	answers.clear()
	final_score = 0
	victory = false
	new_record = false


func register_answer(challenge: Dictionary, action: String, result: String) -> void:
	answers.append({"challenge": challenge, "action": action, "result": result})


func set_result(score: int, did_win: bool) -> void:
	final_score = score
	victory = did_win
	new_record = score > best_score
	if new_record:
		best_score = score
	save()


func set_sound(enabled: bool) -> void:
	sound_on = enabled
	Audio.set_enabled(enabled)
	save()


func mark_tutorial_seen() -> void:
	tutorial_seen = true
	save()


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "best_score", best_score)
	config.set_value("options", "sound_on", sound_on)
	config.set_value("options", "tutorial_seen", tutorial_seen)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_score = config.get_value("progress", "best_score", 0)
	sound_on = config.get_value("options", "sound_on", true)
	tutorial_seen = config.get_value("options", "tutorial_seen", false)
