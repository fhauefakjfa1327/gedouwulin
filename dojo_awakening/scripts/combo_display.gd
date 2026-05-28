extends Control

@onready var combo_label: Label
@onready var damage_label: Label
@onready var animation_player: AnimationPlayer

var display_timer: float = 0.0
var display_duration: float = 2.0

func _ready():
	combo_label = get_node_or_null("ComboLabel")
	damage_label = get_node_or_null("DamageLabel")
	animation_player = get_node_or_null("AnimationPlayer")
	visible = false

func show_combo(combo_count: int, total_damage: int):
	visible = true
	display_timer = display_duration

	if combo_label:
		combo_label.text = "%d HITS!" % combo_count
	if damage_label:
		damage_label.text = "%d DMG" % total_damage

	if combo_label:
		match combo_count:
			2, 3:
				combo_label.modulate = Color.YELLOW
			4, 5:
				combo_label.modulate = Color.ORANGE
			6, 7:
				combo_label.modulate = Color.RED
			_:
				combo_label.modulate = Color.PURPLE

	if animation_player and animation_player.has_animation("show_combo"):
		animation_player.play("show_combo")

func _process(delta: float):
	if visible and display_timer > 0:
		display_timer -= delta
		if display_timer <= 0:
			visible = false
