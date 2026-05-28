extends Node

# GameData - 全局游戏数据管理器（Autoload单例）

var selected_character = {
	"id": "ryuichi",
	"name": "龙一",
	"type": "balanced",
	"description": "均衡型格斗家，易于上手",
	"stats": {
		"health": 100,
		"speed": 150,
		"jump_force": -380,
		"light_punch": 8,
		"heavy_punch": 15,
		"light_kick": 10,
		"heavy_kick": 20,
		"special": 35
	},
	"special_move": "dragon_fist",
	"color": "#E74C3C"
}

var unlocked_characters = ["ryuichi"]  # 移除 Array[String] 强类型
var high_scores = {}  # 移除 Dictionary 强类型
var total_play_time = 0.0
var matches_played = 0
var matches_won = 0

var difficulty = 1
var screen_shake = true
var hit_stop = true
var show_damage_numbers = true

func _ready():
	_load_data()

func _load_data():
	var file = FileAccess.open("user://save_data.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.get_data()
			unlocked_characters = data.get("unlocked_characters", ["ryuichi"])
			high_scores = data.get("high_scores", {})
			total_play_time = data.get("total_play_time", 0.0)
			matches_played = data.get("matches_played", 0)
			matches_won = data.get("matches_won", 0)
			difficulty = data.get("difficulty", 1)

func save_data():
	var data = {
		"unlocked_characters": unlocked_characters,
		"high_scores": high_scores,
		"total_play_time": total_play_time,
		"matches_played": matches_played,
		"matches_won": matches_won,
		"difficulty": difficulty
	}

	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func unlock_character(char_id):
	if not char_id in unlocked_characters:
		unlocked_characters.append(char_id)
		save_data()

func update_high_score(mode, score):
	if not high_scores.has(mode) or score > high_scores[mode]:
		high_scores[mode] = score
		save_data()

func record_match_result(won):
	matches_played += 1
	if won:
		matches_won += 1
	save_data()
