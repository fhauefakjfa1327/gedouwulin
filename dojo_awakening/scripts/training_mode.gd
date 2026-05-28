extends "res://scripts/battle_manager.gd"

class_name TrainingMode

@onready var training_ui: Control = $UI/TrainingUI
@onready var dummy_settings: Panel = $UI/TrainingUI/DummySettings

enum DummyMode { STAND, CROUCH, JUMP, WALK, ATTACK, BLOCK, BLOCK_ALL, RECORD, PLAYBACK }
var dummy_mode: DummyMode = DummyMode.STAND
var is_recording: bool = false
var recorded_inputs = []
var playback_index: int = 0

func _ready():
	round_time = 999.0
	max_rounds = 1
	super._ready()
	_setup_training_ui()

func _setup_training_ui():
	training_ui.visible = true
	var mode_buttons = dummy_settings.get_node("ModeButtons")
	for btn in mode_buttons.get_children():
		if btn is Button:
			btn.pressed.connect(_on_dummy_mode_changed.bind(btn.name))

	var reset_btn = training_ui.get_node("ResetButton")
	reset_btn.pressed.connect(_reset_positions)

	var record_btn = training_ui.get_node("RecordButton")
	record_btn.pressed.connect(_toggle_recording)

func _process(delta):
	if current_state == GameState.FIGHTING:
		_update_timer(delta)
		_update_camera()
		_update_dummy_ai()

func _update_dummy_ai():
	match dummy_mode:
		DummyMode.STAND:
			if enemy.current_state != enemy.State.IDLE:
				enemy.change_state(enemy.State.IDLE)
				enemy.velocity.x = 0

		DummyMode.CROUCH:
			if enemy.current_state != enemy.State.IDLE:
				enemy.change_state(enemy.State.IDLE)

		DummyMode.JUMP:
			if enemy.is_on_floor() and enemy.current_state in [enemy.State.IDLE, enemy.State.WALK]:
				enemy.velocity.y = enemy.jump_force
				enemy.change_state(enemy.State.JUMP)

		DummyMode.WALK:
			if enemy.current_state in [enemy.State.IDLE, enemy.State.WALK]:
				var dir = sign(player.global_position.x - enemy.global_position.x)
				enemy.velocity.x = dir * enemy.walk_speed * 0.5
				enemy.change_state(enemy.State.WALK)

		DummyMode.BLOCK:
			if enemy.can_block():
				enemy.change_state(enemy.State.BLOCK)

		DummyMode.BLOCK_ALL:
			if enemy.can_block():
				enemy.change_state(enemy.State.BLOCK)
			if enemy.current_state in [enemy.State.BLOCK_STUN, enemy.State.HIT_LIGHT]:
				if enemy.can_block():
					enemy.change_state(enemy.State.BLOCK)

		DummyMode.ATTACK:
			if enemy.can_attack() and enemy.current_state in [enemy.State.IDLE, enemy.State.WALK]:
				var attacks = [enemy.State.LIGHT_PUNCH, enemy.State.LIGHT_KICK, 
								enemy.State.HEAVY_PUNCH, enemy.State.HEAVY_KICK]
				enemy.change_state(attacks[randi() % attacks.size()])

func _on_dummy_mode_changed(mode_name: String):
	match mode_name:
		"StandButton": dummy_mode = DummyMode.STAND
		"CrouchButton": dummy_mode = DummyMode.CROUCH
		"JumpButton": dummy_mode = DummyMode.JUMP
		"WalkButton": dummy_mode = DummyMode.WALK
		"AttackButton": dummy_mode = DummyMode.ATTACK
		"BlockButton": dummy_mode = DummyMode.BLOCK
		"BlockAllButton": dummy_mode = DummyMode.BLOCK_ALL
		"RecordButton": dummy_mode = DummyMode.RECORD
		"PlaybackButton": dummy_mode = DummyMode.PLAYBACK

func _reset_positions():
	player.global_position = player_spawn.global_position
	player.reset_fighter()

	enemy.global_position = enemy_spawn.global_position
	enemy.reset_fighter()

	recorded_inputs.clear()
	playback_index = 0

func _toggle_recording():
	if is_recording:
		is_recording = false
	else:
		is_recording = true
		recorded_inputs.clear()

func _input(event: InputEvent):
	if is_recording and event.is_pressed():
		recorded_inputs.append({
			"time": Time.get_time_dict_from_system(),
			"action": event.as_text()
		})

	if event.is_action_pressed("pause"):
		_toggle_pause()

func _end_round(winner):
	pass

func _end_match():
	pass
