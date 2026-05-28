extends Node2D

@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var flash: ColorRect = $Flash

func _ready():
	particles.emitting = true
	particles.one_shot = true

	flash.visible = true
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): flash.visible = false)

	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	queue_free()
