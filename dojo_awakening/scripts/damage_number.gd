extends Label

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 300.0
var lifetime: float = 1.0
var fade_speed: float = 2.0

func _ready():
	velocity = Vector2(randf_range(-30, 30), randf_range(-100, -150))

	label_settings = LabelSettings.new()
	label_settings.font_size = 24
	label_settings.outline_size = 2
	label_settings.outline_color = Color.BLACK

func setup(damage: int, is_critical: bool = false):
	text = str(damage)

	if is_critical:
		label_settings.font_color = Color.RED
		label_settings.font_size = 32
		scale = Vector2(1.2, 1.2)
	else:
		label_settings.font_color = Color.WHITE

func _process(delta: float):
	velocity.y += gravity * delta
	position += velocity * delta

	modulate.a -= fade_speed * delta

	if modulate.a <= 0:
		queue_free()
