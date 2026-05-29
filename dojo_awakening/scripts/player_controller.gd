extends CharacterBody2D

class_name PlayerController

const Fighter = preload("res://scripts/fighter_base.gd")

# ========== 输入映射 ==========
@export var input_prefix: String = ""

# 输入状态
var input_direction: float = 0.0
var is_jump_pressed: bool = false
var is_crouch_pressed: bool = false
var is_block_pressed: bool = false

# 复制 Fighter 基类的关键变量和方法（简化版状态机）
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