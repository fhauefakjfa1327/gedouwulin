extends Node2D

class_name BattleManager

@export var round_time: float = 99.0
@export var max_rounds: int = 3
@export var win_by_ko: bool = true

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawn: Marker2D = $EnemySpawn
@onready var camera: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $UI
@onready var timer_label: Label = $UI/TimerLabel
@onready var round_label: Label = $UI/RoundLabel
@onready var countdown_label: Label = $UI/CountdownLabel
@onready var pause_menu: Control = $UI/PauseMenu
@onready var result_screen: Control = $UI/ResultScreen

enum GameState { INTRO, COUNTDOWN, FIGHTING, ROUND_END, MATCH_END, PAUSED }
var current_state: GameState = GameState.INTRO

var current_round: int = 1
var time_remaining: float
var player_score: int = 0
var enemy_score: int = 0

var player: CharacterBody2D = null
var enemy: CharacterBody2D = null

signal round_started(round_num: int)
signal round_ended(winner: CharacterBody2D)
signal match_ended(final_winner: String)

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

# v2.5 修复：用计时器变量替代 await，避免协程死锁
var _intro_timer: float = 0.0
var _countdown_timer: float = 0.0
var _countdown_value: int = 3
var _round_end_timer: float = 0.0

func _ready():
	if player_scene == null:
		push_warning("player_scene not set in editor, loading manually...")
		player_scene = load("res://scenes/player/player.tscn")
	if enemy_scene == null:
		push_warning("enemy_scene not set in editor, loading manually...")
		enemy_scene = load("res://scenes/enemy/enemy.tscn")

	if player_scene == null:
		push_error("Failed to load player scene!")
		return
	if enemy_scene == null:
		push_error("Failed to load enemy scene!")
		return

	_setup_camera()
	_setup_fighters()
	_setup_ui()
	_start_intro()

func _process(delta: float):
	match current_state:
		GameState.INTRO:
			_process_intro(delta)
		GameState.COUNTDOWN:
			_process_countdown(delta)
		GameState.FIGHTING:
			_update_timer(delta)
			_update_camera()
			_check_round_end()
		GameState.ROUND_END:
			_process_round_end(delta)
		GameState.MATCH_END:
			pass

# ========== v2.5 修复：同步 intro 处理（替代 await）==========
func _start_intro():
	current_state = GameState.INTRO
	round_label.text = "ROUND %d" % current_round
	round_label.visible = true
	_intro_timer = 2.0

func _process_intro(delta: float):
	_intro_timer -= delta
	if _intro_timer <= 0:
		round_label.visible = false
		_start_countdown()

# ========== v2.5 修复：同步 countdown 处理（替代 await）==========
func _start_countdown():
	current_state = GameState.COUNTDOWN
	countdown_label.visible = true
	_countdown_value = 3
	_countdown_timer = 1.0
	countdown_label.text = str(_countdown_value)

func _process_countdown(delta: float):
	_countdown_timer -= delta
	if _countdown_timer <= 0:
		_countdown_value -= 1
		if _countdown_value > 0:
			countdown_label.text = str(_countdown_value)
			_countdown_timer = 1.0
		elif _countdown_value == 0:
			countdown_label.text = "FIGHT!"
			_countdown_timer = 0.5
		else:
			countdown_label.visible = false
			_start_round()

func _start_round():
	current_state = GameState.FIGHTING
	time_remaining = round_time

	if player and player.has_method("reset_fighter"):
		player.reset_fighter()
	if enemy and enemy.has_method("reset_fighter"):
		enemy.reset_fighter()

	round_started.emit(current_round)

func _setup_camera():
	camera.limit_left = -500
	camera.limit_right = 1780
	camera.limit_top = -200
	camera.limit_bottom = 800
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0

func _setup_fighters():
	if player_scene == null or enemy_scene == null:
		push_error("Scene resources not loaded!")
		return

	# v2.5 修复：先实例化两个角色，再一起添加到场景树
	# 这样两者的 _ready() 中的 call_deferred("_find_opponent") 都能在场景树完整后执行
	player = player_scene.instantiate()
	player.global_position = player_spawn.global_position
	_apply_character_data(player, true)

	enemy = enemy_scene.instantiate()
	enemy.global_position = enemy_spawn.global_position
	_apply_character_data(enemy, false)

	# 一起添加进场景树
	add_child(player)
	add_child(enemy)

	# 连接信号
	if player.has_signal("died"):
		player.died.connect(_on_fighter_died.bind(player))
	if player.has_signal("victory"):
		player.victory.connect(_on_fighter_victory.bind(player))
	if enemy.has_signal("died"):
		enemy.died.connect(_on_fighter_died.bind(enemy))
	if enemy.has_signal("victory"):
		enemy.victory.connect(_on_fighter_victory.bind(enemy))

func _apply_character_data(fighter, is_player: bool):
	if fighter == null:
		return

	if is_player and GameData.selected_character != null and GameData.selected_character.has("stats"):
		var stats = GameData.selected_character["stats"]
		fighter.max_health = stats.get("health", 100)
		fighter.health = stats.get("health", 100)
		fighter.walk_speed = stats.get("speed", 150)
		fighter.light_punch_damage = stats.get("light_punch", 8)
		fighter.heavy_punch_damage = stats.get("heavy_punch", 15)
		fighter.light_kick_damage = stats.get("light_kick", 10)
		fighter.heavy_kick_damage = stats.get("heavy_kick", 20)
		fighter.special_damage = stats.get("special", 35)

func _setup_ui():
	pause_menu.visible = false
	result_screen.visible = false
	countdown_label.visible = false

	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	if player and player.has_signal("special_meter_changed"):
		player.special_meter_changed.connect(_on_player_special_changed)
	if enemy and enemy.has_signal("health_changed"):
		enemy.health_changed.connect(_on_enemy_health_changed)
	if enemy and enemy.has_signal("special_meter_changed"):
		enemy.special_meter_changed.connect(_on_enemy_special_changed)

func _update_timer(delta: float):
	time_remaining -= delta
	if time_remaining <= 0:
		time_remaining = 0
		_end_round_by_timeout()

	var seconds = int(time_remaining)
	var ms = int((time_remaining - seconds) * 100)
	timer_label.text = "%02d:%02d" % [seconds, ms]

	if time_remaining <= 10.0:
		timer_label.modulate = Color.RED
	else:
		timer_label.modulate = Color.WHITE

func _update_camera():
	if player == null or enemy == null:
		return

	var mid_point = (player.global_position + enemy.global_position) / 2.0
	mid_point.x = clamp(mid_point.x, camera.limit_left + 640, camera.limit_right - 640)
	mid_point.y = clamp(mid_point.y, camera.limit_top + 360, camera.limit_bottom - 360)

	camera.global_position = mid_point

func _check_round_end():
	if player == null or enemy == null:
		return

	if player.health <= 0:
		_end_round(enemy)
	elif enemy.health <= 0:
		_end_round(player)

func _end_round(winner: CharacterBody2D):
	current_state = GameState.ROUND_END

	if winner == player:
		player_score += 1
	else:
		enemy_score += 1

	if winner and winner.has_method("trigger_victory"):
		winner.trigger_victory()

	var winner_name = "PLAYER" if winner == player else "CPU"
	round_label.text = "%s WINS!" % winner_name
	round_label.visible = true
	_round_end_timer = 2.0

func _process_round_end(delta: float):
	_round_end_timer -= delta
	if _round_end_timer <= 0:
		round_label.visible = false
		if player_score >= 2 or enemy_score >= 2 or current_round >= max_rounds:
			_end_match()
		else:
			current_round += 1
			_start_intro()

func _end_round_by_timeout():
	current_state = GameState.ROUND_END

	var winner: CharacterBody2D = null
	if player.health > enemy.health:
		winner = player
		player_score += 1
	elif enemy.health > player.health:
		winner = enemy
		enemy_score += 1
	else:
		player_score += 1
		enemy_score += 1

	if winner:
		if winner.has_method("trigger_victory"):
			winner.trigger_victory()
		round_label.text = "TIME OVER - %s WINS!" % ("PLAYER" if winner == player else "CPU")
	else:
		round_label.text = "TIME OVER - DRAW!"

	round_label.visible = true
	_round_end_timer = 2.0

func _end_match():
	current_state = GameState.MATCH_END

	var final_winner: String
	if player_score > enemy_score:
		final_winner = "PLAYER"
		GameData.record_match_result(true)
	elif enemy_score > player_score:
		final_winner = "CPU"
		GameData.record_match_result(false)
	else:
		final_winner = "DRAW"

	_show_result_screen(final_winner)
	match_ended.emit(final_winner)

func _show_result_screen(winner: String):
	result_screen.visible = true

	var result_label = result_screen.get_node_or_null("ResultLabel")
	var score_label = result_screen.get_node_or_null("ScoreLabel")

	if result_label:
		if winner == "PLAYER":
			result_label.text = "YOU WIN!"
			result_label.modulate = Color.GREEN
		elif winner == "CPU":
			result_label.text = "YOU LOSE!"
			result_label.modulate = Color.RED
		else:
			result_label.text = "DRAW!"
			result_label.modulate = Color.YELLOW

	if score_label:
		score_label.text = "Score: %d - %d" % [player_score, enemy_score]

func _on_fighter_died(fighter: CharacterBody2D):
	if current_state != GameState.FIGHTING:
		return

	var winner = enemy if fighter == player else player
	_end_round(winner)

func _on_fighter_victory(fighter: CharacterBody2D):
	pass

func _on_player_health_changed(new_health: int, max_health: int):
	var health_bar = ui_layer.get_node_or_null("PlayerHealthBar")
	if health_bar:
		health_bar.value = new_health
		health_bar.max_value = max_health

func _on_player_special_changed(new_meter: float, max_meter: float):
	var special_bar = ui_layer.get_node_or_null("PlayerSpecialBar")
	if special_bar:
		special_bar.value = new_meter
		special_bar.max_value = max_meter

func _on_enemy_health_changed(new_health: int, max_health: int):
	var health_bar = ui_layer.get_node_or_null("EnemyHealthBar")
	if health_bar:
		health_bar.value = new_health
		health_bar.max_value = max_health

func _on_enemy_special_changed(new_meter: float, max_meter: float):
	var special_bar = ui_layer.get_node_or_null("EnemySpecialBar")
	if special_bar:
		special_bar.value = new_meter
		special_bar.max_value = max_meter

func _input(event: InputEvent):
	if event.is_action_pressed("pause") and current_state in [GameState.FIGHTING, GameState.PAUSED]:
		_toggle_pause()

func _toggle_pause():
	if current_state == GameState.PAUSED:
		current_state = GameState.FIGHTING
		pause_menu.visible = false
		get_tree().paused = false
	else:
		current_state = GameState.PAUSED
		pause_menu.visible = true
		get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/stages/main_menu.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

func shake_camera(duration: float, intensity: float):
	if camera and camera.has_method("shake"):
		camera.shake(duration, intensity)