extends Node
## Guarda o resultado da partida, as preferências do jogador e o histórico
## de impacto (quantas situações ele já respondeu com segurança).
## Tudo fica salvo no navegador (user://).

const SAVE_PATH: String = "user://click_seguro.cfg"

## Quanto a opção "Letra grande" aumenta o texto das mensagens.
const LARGE_TEXT_SCALE: float = 1.25
## Velocidade com que o texto aparece: NORMAL, DEVAGAR ou NA HORA (tudo de uma vez).
enum TextSpeed { NORMAL, SLOW, INSTANT }
const TEXT_SPEED_NAMES: Array[String] = ["NORMAL", "DEVAGAR", "NA HORA"]
## Multiplicador do tempo por letra (0 = mostra tudo de uma vez).
const TEXT_SPEED_FACTORS: Array[float] = [1.0, 2.5, 0.0]

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
var large_text: bool = false
var text_speed: int = TextSpeed.NORMAL
var player_name: String = ""

# Histórico de impacto (todas as partidas neste navegador).
var games_played: int = 0
var answers_total: int = 0
var answers_safe: int = 0
var scams_seen: int = 0
var scams_spotted: int = 0
## kind do desafio -> [respostas seguras, total]
var kind_stats: Dictionary = {}


func _ready() -> void:
	_load()


func start_run() -> void:
	answers.clear()
	final_score = 0
	victory = false
	new_record = false


## Resposta "segura" = ideal ou segura (não conta parcial nem insegura).
static func is_safe_result(result: String) -> bool:
	return result == "best" or result == "safe"


func register_answer(challenge: Dictionary, action: String, result: String) -> void:
	answers.append({"challenge": challenge, "action": action, "result": result})

	var ok: bool = is_safe_result(result)
	answers_total += 1
	if ok:
		answers_safe += 1
	if not challenge.get("legit", false):
		scams_seen += 1
		if ok:
			scams_spotted += 1
	var kind: String = challenge["kind"]
	var stat: Array = kind_stats.get(kind, [0, 0])
	kind_stats[kind] = [int(stat[0]) + (1 if ok else 0), int(stat[1]) + 1]
	save()


## Quantas respostas seguras o jogador deu na partida atual.
func run_safe_count() -> int:
	var count: int = 0
	for answer: Dictionary in answers:
		if is_safe_result(answer["result"]):
			count += 1
	return count


func set_result(score: int, did_win: bool) -> void:
	final_score = score
	victory = did_win
	games_played += 1
	new_record = score > best_score
	if new_record:
		best_score = score
	save()


func set_sound(enabled: bool) -> void:
	sound_on = enabled
	Audio.set_enabled(enabled)
	save()


func set_large_text(enabled: bool) -> void:
	large_text = enabled
	save()


## Passa para a próxima velocidade de texto (NORMAL -> DEVAGAR -> NA HORA).
func cycle_text_speed() -> void:
	text_speed = (text_speed + 1) % TEXT_SPEED_NAMES.size()
	save()


func set_player_name(value: String) -> void:
	player_name = value.strip_edges()
	save()


func text_scale() -> float:
	return LARGE_TEXT_SCALE if large_text else 1.0


func typing_factor() -> float:
	return TEXT_SPEED_FACTORS[text_speed]


func mark_tutorial_seen() -> void:
	tutorial_seen = true
	save()


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "best_score", best_score)
	config.set_value("options", "sound_on", sound_on)
	config.set_value("options", "tutorial_seen", tutorial_seen)
	config.set_value("options", "large_text", large_text)
	config.set_value("options", "text_speed", text_speed)
	config.set_value("options", "player_name", player_name)
	config.set_value("impact", "games_played", games_played)
	config.set_value("impact", "answers_total", answers_total)
	config.set_value("impact", "answers_safe", answers_safe)
	config.set_value("impact", "scams_seen", scams_seen)
	config.set_value("impact", "scams_spotted", scams_spotted)
	config.set_value("impact", "kind_stats", kind_stats)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_score = config.get_value("progress", "best_score", 0)
	sound_on = config.get_value("options", "sound_on", true)
	tutorial_seen = config.get_value("options", "tutorial_seen", false)
	large_text = config.get_value("options", "large_text", false)
	text_speed = clampi(config.get_value("options", "text_speed", TextSpeed.NORMAL), 0, TEXT_SPEED_NAMES.size() - 1)
	player_name = config.get_value("options", "player_name", "")
	games_played = config.get_value("impact", "games_played", 0)
	answers_total = config.get_value("impact", "answers_total", 0)
	answers_safe = config.get_value("impact", "answers_safe", 0)
	scams_seen = config.get_value("impact", "scams_seen", 0)
	scams_spotted = config.get_value("impact", "scams_spotted", 0)
	kind_stats = config.get_value("impact", "kind_stats", {})
