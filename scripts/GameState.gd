extends Node

var final_score: int = 0
var victory: bool = false


func set_result(score: int, did_win: bool) -> void:
	final_score = score
	victory = did_win
