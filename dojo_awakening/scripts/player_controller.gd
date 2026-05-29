extends CharacterBody2D

class_name PlayerController

# ========== 输入映射 ==========
@export var input_prefix: String = ""

# 输入状态
var input_direction: float = 0.0
var is_jump_pressed: bool = false
var is_crouch_pressed: bool = false
var is_block_pressed: bool = false

enum State {
	IDLE, WALK, JUMP, FALL,
	LIGHT_PUNCH, HEAVY_PUNCH, LIGHT_KICK, HEAVY_KICK,
	BLOCK, BLOCK_STUN,
	HIT_LIGHT, HIT_HEAVY, KNOCKDOWN, GETUP,
	SPECIAL, WIN, DEAD
}

@export var fighter_name: String = "Player"
@export var max_health: int = 100
@export var walk_speed: float = 150.0
@export var jump_force: float = -380.0
@export var gravity: float = 980.0

@export var light_punch_damage: int = 8
@export var heavy_punch_damage: int = 15
@export var light_kick_damage: int = 10
@export var heavy_kick_damage: int = 20
@export var special_damage: int = 35

@export var light_punch_startup: float = 0.08
@export var light_punch_active: float = 0.1
@export var light_punch_recovery: float = 0.12
@export var heavy_punch_startup: float = 0.15
@export var heavy_punch_active: float = 0.12
@export var heavy_punch_recovery: float = 0.25
@export var block_stun_duration: float = 0.3
@export var hit_stun_duration: float = 0.4
@export var knockdown_duration: float = 1.0
@export var combo_window: float = 0.5

@export var attack_max_duration: float = 1.5
@export var special_max_duration: float = 2.0
@export var getup_max_duration: float = 1.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var ground_check: RayCast2D = $GroundCheck
@onready var state_label: Label = $StateLabel

var current_state: State = State.IDLE
var health: int
var special_meter: float = 0.0
var max_special_meter: float = 100.0
var combo_count: int = 0
var combo_timer: float = 0.0
var state_timer: float = 0.0
var is_invincible: bool = false
var facing_right: bool = true
var opponent: CharacterBody2D = null

# 攻击阶段追踪
var _attack_phase: String = ""
var _attack_damage: int = 0
var _attack_duration_remaining: float = 0.0
var _attack_is_heavy: bool = false
var _hitbox_was_active: bool = false

# 安全计时器
var _state_safety_timer: float = 0.0
var _max_safety_time: float = 3.0

# 攻击冷却
var _attack_cooldown: float = 0.0
var _attack_cooldown_time: float = 0.05

signal health_changed(new_health: int, max_health: int)
signal special_meter_changed(new_meter: float, max_meter: float)
signal combo_executed(combo_count: int, total_damage: int)
signal died
signal victory

func _ready():
	health = max_health
	add_to_group("fighter")
	add_to_group("player")

	collision_layer = 2
	collision_mask = 7

	hitbox.collision_layer = 8
	hitbox.collision_mask = 16
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 8

	hitbox.area_entered.connect(_on_hitbox_entered)
	hurtbox.area_entered.connect(_on_hurtbox_entered)
	hitbox.monitoring = false

	# 安全连接动画信号
	if sprite and sprite.sprite_frames != null:
		var has_non_looping = false
		for anim_name in sprite.sprite_frames.get_animation_names():
			if not sprite.sprite_frames.get_animation_loop(anim_name):
				has_non_looping = true
				break
		if has_non_looping:
			sprite.animation_finished.connect(_on_animation_finished)
			sprite.animation_looped.connect(_on_animation_looped)

	# v2.5 修复：使用 call_deferred 延迟查找对手，确保场景树完整
	call_deferred("_find_opponent")
	_update_ui()

func _physics_process(delta: float):
	# 限制 delta 防止跳帧雪崩
	delta = min(delta, 0.05)

	# v2.5 修复：先执行物理更新，再处理输入
	# 这样 is_on_floor() 在 _handle_input 中更准确
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0:
			velocity.y = 0

	_read_input()
	_handle_input()

	state_timer += delta
	_state_safety_timer += delta

	if _attack_cooldown > 0:
		_attack_cooldown = max(0.0, _attack_cooldown - delta)

	_process_attack_phase(delta)

	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			_reset_combo()

	_process_state(delta)
	_check_safety_timeout()
	_face_opponent()
	move_and_slide()

	if state_label:
		state_label.text = State.keys()[current_state]

func _process_attack_phase(delta: float):
	if _attack_phase == "":
		return

	_attack_duration_remaining -= delta

	match _attack_phase:
		"startup":
			if _attack_duration_remaining <= 0:
				_attack_phase = "active"
				_attack_duration_remaining = _get_current_attack_active_time()
				_hitbox_active(_attack_damage, _attack_duration_remaining)
		"active":
			if _attack_duration_remaining <= 0:
				_hitbox_deactivate()
				_attack_phase = "recovery"
				_attack_duration_remaining = _get_current_attack_recovery_time()
		"recovery":
			if _attack_duration_remaining <= 0:
				_attack_phase = ""
				if current_state in [State.LIGHT_PUNCH, State.HEAVY_PUNCH,
									 State.LIGHT_KICK, State.HEAVY_KICK, State.SPECIAL]:
					change_state(State.IDLE)

func _get_current_attack_active_time() -> float:
	match current_state:
		State.LIGHT_PUNCH, State.LIGHT_KICK:
			return light_punch_active
		State.HEAVY_PUNCH, State.HEAVY_KICK:
			return heavy_punch_active
		State.SPECIAL:
			return 0.4
	return 0.1

func _get_current_attack_recovery_time() -> float:
	match current_state:
		State.LIGHT_PUNCH, State.LIGHT_KICK:
			return light_punch_recovery
		State.HEAVY_PUNCH, State.HEAVY_KICK:
			return heavy_punch_recovery
		State.SPECIAL:
			return 0.5
	return 0.1

func _get_current_attack_startup_time() -> float:
	match current_state:
		State.LIGHT_PUNCH, State.LIGHT_KICK:
			return light_punch_startup
		State.HEAVY_PUNCH, State.HEAVY_KICK:
			return heavy_punch_startup
		State.SPECIAL:
			return 0.3
	return 0.1

func _check_safety_timeout():
	if _state_safety_timer < _max_safety_time:
		return

	match current_state:
		State.LIGHT_PUNCH, State.HEAVY_PUNCH, State.LIGHT_KICK, State.HEAVY_KICK:
			_hitbox_deactivate()
			_attack_phase = ""
			change_state(State.IDLE)
		State.SPECIAL:
			_hitbox_deactivate()
			_attack_phase = ""
			is_invincible = false
			change_state(State.IDLE)
		State.HIT_LIGHT, State.HIT_HEAVY:
			if health > 0:
				change_state(State.IDLE)
			else:
				change_state(State.DEAD)
		State.KNOCKDOWN:
			if is_on_floor():
				change_state(State.GETUP)
		State.GETUP:
			change_state(State.IDLE)
		State.BLOCK_STUN:
			change_state(State.IDLE)
		State.BLOCK:
			change_state(State.IDLE)
		_:
			change_state(State.IDLE)

	_state_safety_timer = 0.0
	print("[Player安全超时] 强制状态转换: %s -> IDLE" % State.keys()[current_state])

func _process_state(delta: float):
	match current_state:
		State.IDLE:
			velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
			if not is_on_floor():
				change_state(State.FALL)
			elif sprite and sprite.animation != "idle":
				sprite.play("idle")

		State.WALK:
			if not is_on_floor():
				change_state(State.FALL)
			elif sprite and sprite.animation != "walk":
				sprite.play("walk")

		State.JUMP:
			if velocity.y > 0:
				change_state(State.FALL)
			elif sprite and sprite.animation != "jump":
				sprite.play("jump")

		State.FALL:
			if is_on_floor():
				change_state(State.IDLE)
			elif sprite and sprite.animation != "fall":
				sprite.play("fall")

		State.LIGHT_PUNCH, State.HEAVY_PUNCH, State.LIGHT_KICK, State.HEAVY_KICK:
			velocity.x = lerp(velocity.x, 0.0, 15.0 * delta)
			if sprite and not sprite.is_playing() and _attack_phase == "":
				change_state(State.IDLE)

		State.BLOCK:
			velocity.x = lerp(velocity.x, 0.0, 20.0 * delta)
			if sprite and sprite.animation != "block":
				sprite.play("block")
			if not is_block_pressed:
				change_state(State.IDLE)

		State.BLOCK_STUN:
			velocity.x = lerp(velocity.x, 0.0, 20.0 * delta)
			if state_timer >= block_stun_duration:
				change_state(State.IDLE)

		State.HIT_LIGHT, State.HIT_HEAVY:
			velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
			if state_timer >= hit_stun_duration:
				change_state(State.IDLE) if health > 0 else change_state(State.DEAD)

		State.KNOCKDOWN:
			velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
			if state_timer >= knockdown_duration and is_on_floor():
				change_state(State.GETUP)

		State.GETUP:
			velocity.x = lerp(velocity.x, 0.0, 20.0 * delta)
			if state_timer >= getup_max_duration:
				change_state(State.IDLE)
			elif sprite and not sprite.is_playing():
				change_state(State.IDLE)

		State.SPECIAL:
			velocity.x = lerp(velocity.x, 0.0, 15.0 * delta)
			if state_timer >= special_max_duration:
				is_invincible = false
				change_state(State.IDLE)
			elif sprite and not sprite.is_playing() and _attack_phase == "":
				change_state(State.IDLE)

		State.WIN:
			velocity.x = lerp(velocity.x, 0.0, 20.0 * delta)
			if sprite and sprite.animation != "win":
				sprite.play("win")

		State.DEAD:
			velocity.x = lerp(velocity.x, 0.0, 20.0 * delta)
			if sprite and sprite.animation != "dead":
				sprite.play("dead")

func change_state(new_state: State):
	if current_state == new_state:
		return

	if current_state in [State.LIGHT_PUNCH, State.HEAVY_PUNCH, State.LIGHT_KICK,
						 State.HEAVY_KICK, State.SPECIAL]:
		_hitbox_deactivate()
		_attack_phase = ""

	if current_state == State.KNOCKDOWN or current_state == State.SPECIAL:
		is_invincible = false

	current_state = new_state
	state_timer = 0.0
	_state_safety_timer = 0.0

	match new_state:
		State.IDLE:
			if sprite: sprite.play("idle")
		State.WALK:
			if sprite: sprite.play("walk")
		State.JUMP:
			if sprite: sprite.play("jump")
		State.FALL:
			if sprite: sprite.play("fall")
		State.LIGHT_PUNCH:
			_start_attack_sync(light_punch_damage, light_punch_startup, false)
			if sprite: sprite.play("light_punch")
		State.HEAVY_PUNCH:
			_start_attack_sync(heavy_punch_damage, heavy_punch_startup, true)
			if sprite: sprite.play("heavy_punch")
		State.LIGHT_KICK:
			_start_attack_sync(light_kick_damage, light_punch_startup, false)
			if sprite: sprite.play("light_kick")
		State.HEAVY_KICK:
			_start_attack_sync(heavy_kick_damage, heavy_punch_startup, true)
			if sprite: sprite.play("heavy_kick")
		State.BLOCK:
			if sprite: sprite.play("block")
		State.BLOCK_STUN:
			if sprite: sprite.play("block_hit")
		State.HIT_LIGHT:
			if sprite: sprite.play("hit_light")
		State.HIT_HEAVY:
			if sprite: sprite.play("hit_heavy")
		State.KNOCKDOWN:
			if sprite: sprite.play("knockdown")
			is_invincible = true
		State.GETUP:
			if sprite: sprite.play("getup")
		State.SPECIAL:
			_start_special_attack_sync()
			if sprite: sprite.play("special")
		State.WIN:
			if sprite: sprite.play("win")
			victory.emit()
		State.DEAD:
			if sprite: sprite.play("dead")
			died.emit()

func _start_attack_sync(damage: int, startup: float, is_heavy: bool):
	_attack_phase = "startup"
	_attack_damage = damage
	_attack_is_heavy = is_heavy
	_attack_duration_remaining = startup
	_hitbox_was_active = false

func _start_special_attack_sync():
	is_invincible = true
	special_meter = 0.0
	special_meter_changed.emit(special_meter, max_special_meter)
	_attack_phase = "startup"
	_attack_damage = special_damage
	_attack_is_heavy = true
	_attack_duration_remaining = 0.3
	_hitbox_was_active = false

func _hitbox_active(damage: int, duration: float):
	hitbox.monitoring = true
	_hitbox_was_active = true
	var attack_data = {
		"damage": damage,
		"knockback": Vector2(80.0 * (1.0 if facing_right else -1.0), -30.0),
		"hit_stun": hit_stun_duration,
		"attacker": self,
		"is_heavy": damage >= 15 or _attack_is_heavy
	}
	hitbox.set_meta("attack_data", attack_data)

func _hitbox_deactivate():
	if _hitbox_was_active:
		hitbox.monitoring = false
		_hitbox_was_active = false
		if hitbox.has_meta("attack_data"):
			hitbox.remove_meta("attack_data")

func _on_animation_finished():
	if current_state == State.GETUP:
		change_state(State.IDLE)
	elif current_state in [State.LIGHT_PUNCH, State.HEAVY_PUNCH,
						  State.LIGHT_KICK, State.HEAVY_KICK] and _attack_phase == "":
		change_state(State.IDLE)
	elif current_state == State.SPECIAL and _attack_phase == "":
		is_invincible = false
		change_state(State.IDLE)

func _on_animation_looped():
	pass

func _on_hurtbox_entered(area: Area2D):
	if not area.is_in_group("hitbox"):
		return

	var attacker = area.get_parent()
	if attacker == self:
		return

	if not area.has_meta("attack_data"):
		return

	var attack_data = area.get_meta("attack_data")
	_take_damage(attack_data)

func _on_hitbox_entered(area: Area2D):
	pass

func _take_damage(attack_data: Dictionary):
	if is_invincible:
		return

	var damage: int = attack_data["damage"]
	var knockback: Vector2 = attack_data["knockback"]
	var is_heavy: bool = attack_data["is_heavy"]
	var attacker = attack_data["attacker"]

	if current_state in [State.LIGHT_PUNCH, State.HEAVY_PUNCH,
						 State.LIGHT_KICK, State.HEAVY_KICK, State.SPECIAL]:
		_hitbox_deactivate()
		_attack_phase = ""

	if current_state == State.BLOCK:
		var block_direction = 1.0 if facing_right else -1.0
		var attack_direction = sign(knockback.x)

		if block_direction != attack_direction:
			health -= damage
			velocity = knockback * 1.5
			change_state(State.KNOCKDOWN)
		else:
			damage = int(damage * 0.1)
			health -= damage
			velocity = knockback * 0.1
			change_state(State.BLOCK_STUN)
			special_meter = min(special_meter + 5.0, max_special_meter)
			if attacker and attacker.has_method("_gain_special"):
				attacker.special_meter = min(attacker.special_meter + 2.0, attacker.max_special_meter)
	else:
		health -= damage
		velocity = knockback

		special_meter = min(special_meter + 3.0, max_special_meter)
		if attacker and attacker.has_method("_gain_special"):
			attacker.special_meter = min(attacker.special_meter + 5.0, attacker.max_special_meter)

		if attacker and attacker.has_method("_register_hit"):
			attacker._register_hit(damage)

		if is_heavy and health > 0:
			change_state(State.KNOCKDOWN)
		elif health > 0:
			change_state(State.HIT_HEAVY if is_heavy else State.HIT_LIGHT)
		else:
			change_state(State.DEAD)

	health = max(health, 0)
	health_changed.emit(health, max_health)
	special_meter_changed.emit(special_meter, max_special_meter)

func _register_hit(damage: int):
	combo_count += 1
	combo_timer = combo_window

	if combo_count >= 2:
		combo_executed.emit(combo_count, damage * combo_count)

func _reset_combo():
	combo_count = 0
	combo_timer = 0.0

func _read_input():
	input_direction = Input.get_axis("move_left", "move_right")
	is_jump_pressed = Input.is_action_just_pressed("jump")
	is_crouch_pressed = Input.is_action_pressed("crouch")
	is_block_pressed = Input.is_action_pressed("block")

# v2.5 修复：修复 WALK/IDLE 震荡逻辑
func _handle_input():
	if _attack_cooldown > 0:
		return

	if current_state in [State.HIT_LIGHT, State.HIT_HEAVY, State.KNOCKDOWN,
						 State.BLOCK_STUN, State.GETUP, State.DEAD, State.WIN]:
		return

	if is_block_pressed and can_block():
		change_state(State.BLOCK)
		return

	if Input.is_action_just_pressed("special") and can_special():
		change_state(State.SPECIAL)
		_attack_cooldown = 0.3
		return

	if is_jump_pressed and is_on_floor():
		velocity.y = jump_force
		change_state(State.JUMP)
		return

	if is_crouch_pressed and is_on_floor() and current_state in [State.IDLE, State.WALK]:
		if sprite:
			sprite.play("crouch")
		return

	if Input.is_action_just_pressed("light_punch") and can_attack():
		change_state(State.LIGHT_PUNCH)
		_attack_cooldown = _attack_cooldown_time
	elif Input.is_action_just_pressed("heavy_punch") and can_attack():
		change_state(State.HEAVY_PUNCH)
		_attack_cooldown = _attack_cooldown_time
	elif Input.is_action_just_pressed("light_kick") and can_attack():
		change_state(State.LIGHT_KICK)
		_attack_cooldown = _attack_cooldown_time
	elif Input.is_action_just_pressed("heavy_kick") and can_attack():
		change_state(State.HEAVY_KICK)
		_attack_cooldown = _attack_cooldown_time
	elif input_direction != 0 and current_state in [State.IDLE, State.WALK]:
		# v2.5 修复：只在 IDLE 时切换到 WALK，不在 WALK 时切换回 IDLE
		velocity.x = input_direction * walk_speed
		if current_state == State.IDLE:
			change_state(State.WALK)
	elif input_direction == 0 and current_state == State.WALK:
		# v2.5 修复：没有输入且正在走路时，切换回 IDLE
		change_state(State.IDLE)

func _face_opponent():
	if opponent == null:
		return

	var dir = opponent.global_position.x - global_position.x
	if abs(dir) > 5.0:
		facing_right = dir > 0
		if sprite:
			sprite.flip_h = not facing_right

	var hitbox_pos = hitbox.position
	hitbox_pos.x = abs(hitbox_pos.x) * (1.0 if facing_right else -1.0)
	hitbox.position = hitbox_pos

func _find_opponent():
	if not is_inside_tree():
		return
	var fighters = get_tree().get_nodes_in_group("fighter")
	for f in fighters:
		if f != self:
			opponent = f
			break

func _update_ui():
	health_changed.emit(health, max_health)
	special_meter_changed.emit(special_meter, max_special_meter)

func can_attack() -> bool:
	return current_state in [State.IDLE, State.WALK, State.JUMP]

func can_block() -> bool:
	return current_state in [State.IDLE, State.WALK] and is_on_floor()

func can_special() -> bool:
	return special_meter >= max_special_meter and current_state in [State.IDLE, State.WALK]

func trigger_victory():
	change_state(State.WIN)

func reset_fighter():
	health = max_health
	special_meter = 0.0
	combo_count = 0
	velocity = Vector2.ZERO
	_attack_phase = ""
	_hitbox_deactivate()
	change_state(State.IDLE)
	_update_ui()