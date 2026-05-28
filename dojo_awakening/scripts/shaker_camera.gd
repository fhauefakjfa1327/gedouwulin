extends Camera2D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	original_offset = offset

func _process(delta: float):
	if shake_timer > 0:
		shake_timer -= delta
		var intensity = shake_intensity * (shake_timer / shake_duration)
		offset = original_offset + Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
	else:
		offset = original_offset

func shake(duration: float, intensity: float):
	shake_duration = duration
	shake_intensity = intensity
	shake_timer = duration
