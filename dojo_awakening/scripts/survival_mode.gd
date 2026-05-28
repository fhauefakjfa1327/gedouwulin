extends "res://scripts/battle_manager.gd"

class_name SurvivalMode

var current_enemy_index: int = 0
var enemy_difficulty_multiplier: float = 1.0

var enemy_configs = [
	{"name": "学徒", "difficulty": 0, "health_mult": 0.8, "damage_mult": 0.7},
	{"name": "弟子", "difficulty": 0, "health_mult": 1.0, "damage_mult": 0.8},
	{"name": "高手", "difficulty": 1, "health_mult": 1.0, "damage_mult": 1.0},
	{"name": "大师", "difficulty": 1, "health_mult": 1.2, "damage_mult": 1.1},
	{"name": "宗师", "difficulty": 2, "health_mult": 1.2, "damage_mult": 1.2},
	{"name": "传说", "difficulty": 2, "health_mult": 1.5, "damage_mult": 1.3},
	{"name": "神话", "difficulty": 3, "health_mult": 1.5, "damage_mult": 1.5}
]

func _ready():
	max_rounds = 999
	super._ready()

func _start_round():
	current_state = GameState.FIGHTING
	time_remaining = round_time

	player.reset_fighter()
	_setup_enemy_for_wave()

	round_started.emit(current_round)

func _setup_enemy_for_wave():
	var config_index = min(current_enemy_index, enemy_configs.size() - 1)
	var config = enemy_configs[config_index]

	enemy.max_health = int(enemy.max_health * config["health_mult"] * enemy_difficulty_multiplier)
	enemy.health = enemy.max_health

	enemy.difficulty = config["difficulty"]

	if current_round % 3 == 0:
		enemy_difficulty_multiplier += 0.1

	enemy.reset_fighter()

func _end_round(winner):
	if winner == player:
		current_enemy_index += 1
		current_round += 1

		player.health = min(player.health + 20, player.max_health)
		player.health_changed.emit(player.health, player.max_health)

		round_label.text = "WAVE %d CLEARED!" % (current_round - 1)
		round_label.visible = true
		await get_tree().create_timer(1.5).timeout
		round_label.visible = false

		_start_round()
	else:
		_show_survival_result()

func _show_survival_result():
	current_state = GameState.MATCH_END

	GameData.update_high_score("survival", current_round - 1)
	GameData.record_match_result(false)

	result_screen.visible = true
	var result_label = result_screen.get_node("ResultLabel")
	var score_label = result_screen.get_node("ScoreLabel")

	result_label.text = "SURVIVAL OVER"
	result_label.modulate = Color.ORANGE
	score_label.text = "Waves Survived: %d" % (current_round - 1)

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
